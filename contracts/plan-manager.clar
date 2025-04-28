;; plan-manager.clar
;; Manages subscription plans configuration

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u400))
(define-constant ERR_INVALID_PRICE (err u401))
(define-constant ERR_INVALID_PERIOD (err u402))
(define-constant ERR_INVALID_PLAN (err u403))
(define-constant ERR_PLAN_EXISTS (err u404))
(define-constant ERR_PLAN_PAUSED (err u405))

;; Token types
(define-constant TOKEN_TYPE_STX u0)
(define-constant TOKEN_TYPE_SIP010 u1)

;; Plan data structure
(define-map plans uint {
  creator: principal,
  name: (string-ascii 64),
  description: (string-ascii 256),
  price: uint,
  period: uint,
  token-type: uint,
  token-contract: (optional principal),
  active: bool,
  created-at: uint
})

;; Track total number of plans
(define-data-var last-plan-id uint u0)

;; Create a new subscription plan
(define-public (create-plan 
  (name (string-ascii 64))
  (description (string-ascii 256))
  (price uint)
  (period uint)
  (token-type uint)
  (token-contract (optional principal))
)
  (begin
    ;; Check platform is active
    (asserts! (contract-call? .admin is-platform-active) (err u406))
    
    ;; Validate inputs
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (> period u0) ERR_INVALID_PERIOD)
    (asserts! (or (is-eq token-type TOKEN_TYPE_STX)
                 (is-eq token-type TOKEN_TYPE_SIP010)) (err u407))
    
    ;; If using SIP-010, token contract must be specified
    (asserts! (or (is-eq token-type TOKEN_TYPE_STX)
                 (is-some token-contract)) (err u408))
    
    ;; Generate new plan ID
    (let ((plan-id (+ (var-get last-plan-id) u1)))
      ;; Update state
      (var-set last-plan-id plan-id)
      (map-set plans plan-id {
        creator: tx-sender,
        name: name,
        description: description,
        price: price,
        period: period,
        token-type: token-type,
        token-contract: token-contract,
        active: true,
        created-at: block-height
      })
      (ok plan-id))))

;; Update an existing plan
(define-public (update-plan
  (plan-id uint)
  (name (string-ascii 64))
  (description (string-ascii 256))
  (price uint)
  (period uint)
)
  (let ((plan (unwrap! (map-get? plans plan-id) ERR_INVALID_PLAN)))
    ;; Check platform is active
    (asserts! (contract-call? .admin is-platform-active) (err u406))
    
    ;; Only plan creator can update
    (asserts! (is-eq (get creator plan) tx-sender) ERR_NOT_AUTHORIZED)
    
    ;; Validate inputs
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (asserts! (> period u0) ERR_INVALID_PERIOD)
    
    ;; Update plan
    (map-set plans plan-id (merge plan {
      name: name,
      description: description,
      price: price,
      period: period
    }))
    (ok plan-id)))

;; Pause a plan
(define-public (pause-plan (plan-id uint))
  (let ((plan (unwrap! (map-get? plans plan-id) ERR_INVALID_PLAN)))
    ;; Only plan creator can pause
    (asserts! (is-eq (get creator plan) tx-sender) ERR_NOT_AUTHORIZED)
    
    ;; Check it's not already paused
    (asserts! (get active plan) (err u409))
    
    ;; Update status
    (map-set plans plan-id (merge plan {active: false}))
    (ok plan-id)))

;; Activate a paused plan
(define-public (activate-plan (plan-id uint))
  (let ((plan (unwrap! (map-get? plans plan-id) ERR_INVALID_PLAN)))
    ;; Only plan creator can activate
    (asserts! (is-eq (get creator plan) tx-sender) ERR_NOT_AUTHORIZED)
    
    ;; Check platform is active
    (asserts! (contract-call? .admin is-platform-active) (err u406))
    
    ;; Check it's currently paused
    (asserts! (not (get active plan)) (err u410))
    
    ;; Update status
    (map-set plans plan-id (merge plan {active: true}))
    (ok plan-id)))

;; Get plan details
(define-read-only (get-plan (plan-id uint))
  (map-get? plans plan-id))

;; Check if a plan is active
(define-read-only (is-plan-active (plan-id uint))
  (match (map-get? plans plan-id)
    plan (get active plan)
    false))

;; Get total number of plans
(define-read-only (get-plan-count)
  (var-get last-plan-id))

;; Get multiple plans by ID range
(define-read-only (get-plans-by-range (start-id uint) (end-id uint))
  (let ((result (list)))
    (fold get-plan-reducer 
          (generate-sequence start-id end-id) 
          result)))

;; Helper for get-plans-by-range
(define-private (get-plan-reducer (plan-id uint) (result (list 256 {id: uint, plan: (optional (tuple (creator principal) (name (string-ascii 64)) (description (string-ascii 256)) (price uint) (period uint) (token-type uint) (token-contract (optional principal)) (active bool) (created-at uint)))})))
  (append result {id: plan-id, plan: (map-get? plans plan-id)}))

;; Helper to generate a sequence of integers
(define-private (generate-sequence (start uint) (end uint))
  (if (> start end)
    (list)
    (append (list start) (generate-sequence (+ start u1) end))))