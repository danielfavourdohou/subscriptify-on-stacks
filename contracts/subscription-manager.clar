;; subscription-manager.clar
;; Manages user subscriptions, handles payments and renewals

(define-constant ERR_INVALID_PLAN (err u500))
(define-constant ERR_PLAN_INACTIVE (err u501))
(define-constant ERR_PAYMENT_FAILED (err u502))
(define-constant ERR_SUBSCRIPTION_NOT_FOUND (err u503))
(define-constant ERR_SUBSCRIPTION_EXPIRED (err u504))
(define-constant ERR_SUBSCRIPTION_ACTIVE (err u505))
(define-constant ERR_INVALID_SUBSCRIBER (err u506))
(define-constant ERR_PLATFORM_PAUSED (err u507))

;; Subscription data structure
(define-map subscriptions {subscriber: principal, plan-id: uint} {
  expiry: uint,
  last-payment: uint,
  payments-count: uint
})

;; Track all subscriber plans for a user
(define-map subscriber-plans principal (list 100 uint))

;; Subscribe to a plan
(define-public (subscribe (plan-id uint))
  (let ((plan (unwrap! (contract-call? .plan-manager get-plan plan-id) ERR_INVALID_PLAN)))
    ;; Check platform is active
    (asserts! (contract-call? .admin is-platform-active) ERR_PLATFORM_PAUSED)
    
    ;; Check plan is active
    (asserts! (get active plan) ERR_PLAN_INACTIVE)
    
    ;; Calculate expiry
    (let ((expiry (+ block-height (get period plan)))
          (subscription-key {subscriber: tx-sender, plan-id: plan-id}))
      
      ;; Process payment
      (asserts! (process-payment plan tx-sender (get price plan)) ERR_PAYMENT_FAILED)
      
      ;; Store subscription
      (map-set subscriptions subscription-key {
        expiry: expiry,
        last-payment: block-height,
        payments-count: u1
      })
      
      ;; Add to subscriber plans
      (add-to-subscriber-plans tx-sender plan-id)
      
      ;; Mint NFT pass
      (try! (contract-call? .pass-nft mint tx-sender plan-id expiry))
      
      (ok expiry))))

;; Renew an existing subscription
(define-public (renew (plan-id uint))
  (let ((plan (unwrap! (contract-call? .plan-manager get-plan plan-id) ERR_INVALID_PLAN))
        (subscription-key {subscriber: tx-sender, plan-id: plan-id})
        (current-subscription (unwrap! (map-get? subscriptions subscription-key) ERR_SUBSCRIPTION_NOT_FOUND)))
    
    ;; Check platform is active
    (asserts! (contract-call? .admin is-platform-active) ERR_PLATFORM_PAUSED)
    
    ;; Check plan is active
    (asserts! (get active plan) ERR_PLAN_INACTIVE)
    
    ;; Process payment
    (asserts! (process-payment plan tx-sender (get price plan)) ERR_PAYMENT_FAILED)
    
    ;; Calculate new expiry
    (let ((current-expiry (get expiry current-subscription))
          (period (get period plan))
          (new-expiry (if (> current-expiry block-height)
                         (+ current-expiry period)    ;; Extend from current expiry if still active
                         (+ block-height period))))   ;; Start from now if expired
      
      ;; Update subscription
      (map-set subscriptions subscription-key {
        expiry: new-expiry,
        last-payment: block-height,
        payments-count: (+ (get payments-count current-subscription) u1)
      })
      
      ;; Update NFT metadata
      (try! (contract-call? .pass-nft update-expiry tx-sender plan-id new-expiry))
      
      (ok new-expiry))))

;; Cancel a subscription
(define-public (cancel (plan-id uint))
  (let ((subscription-key {subscriber: tx-sender, plan-id: plan-id})
        (current-subscription (unwrap! (map-get? subscriptions subscription-key) ERR_SUBSCRIPTION_NOT_FOUND)))
    
    ;; Check platform is active
    (asserts! (contract-call? .admin is-platform-active) ERR_PLATFORM_PAUSED)
    
    ;; Remove from subscriber plans
    (remove-from-subscriber-plans tx-sender plan-id)
    
    ;; Don't delete subscription record entirely, just set expiry to current block
    (map-set subscriptions subscription-key 
      (merge current-subscription {expiry: block-height}))
    
    ;; Burn the NFT pass
    (try! (contract-call? .pass-nft burn tx-sender plan-id))
    
    (ok true)))

;; Process payment based on token type
(define-private (process-payment (plan (tuple (creator principal) (name (string-ascii 64)) (description (string-ascii 256)) (price uint) (period uint) (token-type uint) (token-contract (optional principal)) (active bool) (created-at uint))) (payer principal) (amount uint))
  (let ((fee-amount (contract-call? .admin calculate-admin-fee amount))
        (creator-amount (- amount fee-amount))
        (fee-address (contract-call? .admin get-fee-address))
        (token-type (get token-type plan))
        (token-contract (get token-contract plan)))
    
    (if (is-eq token-type u0)
        ;; STX payment
        (and (is-ok (stx-transfer? amount payer (as-contract tx-sender)))
             (is-ok (as-contract (stx-transfer? creator-amount tx-sender (get creator plan))))
             (is-ok (as-contract (stx-transfer? fee-amount tx-sender fee-address))))
        
        ;; SIP-010 token payment
        (match token-contract
          token-principal (contract-call? .token-payment process-token-payment 
                                          token-principal 
                                          payer 
                                          (get creator plan) 
                                          fee-address 
                                          amount)
          false))))

;; Get subscription expiry
(define-read-only (get-expiry (subscriber principal) (plan-id uint))
  (match (map-get? subscriptions {subscriber: subscriber, plan-id: plan-id})
    subscription (ok (get expiry subscription))
    (err ERR_SUBSCRIPTION_NOT_FOUND)))

;; Get subscription details
(define-read-only (get-subscription (subscriber principal) (plan-id uint))
  (map-get? subscriptions {subscriber: subscriber, plan-id: plan-id}))

;; Get all subscriptions for a user
(define-read-only (get-all-subscriptions (subscriber principal))
  (let ((plan-ids (default-to (list) (map-get? subscriber-plans subscriber))))
    (ok (fold get-subscription-details plan-ids (list)))))

;; Helper for get-all-subscriptions
(define-private (get-subscription-details 
  (plan-id uint) 
  (result (list 100 {plan-id: uint, expiry: uint}))
)
  (match (map-get? subscriptions {subscriber: tx-sender, plan-id: plan-id})
    subscription (append result {plan-id: plan-id, expiry: (get expiry subscription)})
    result))

;; Add plan to subscriber's list of plans
(define-private (add-to-subscriber-plans (subscriber principal) (plan-id uint))
  (let ((current-plans (default-to (list) (map-get? subscriber-plans subscriber))))
    (map-set subscriber-plans 
             subscriber 
             (union (list plan-id) current-plans))))

;; Remove plan from subscriber's list of plans
(define-private (remove-from-subscriber-plans (subscriber principal) (plan-id uint))
  (let ((current-plans (default-to (list) (map-get? subscriber-plans subscriber))))
    (map-set subscriber-plans 
             subscriber 
             (filter remove-plan-filter current-plans))))

;; Helper for remove-from-subscriber-plans
(define-private (remove-plan-filter (id uint))
  (not (is-eq id plan-id)))