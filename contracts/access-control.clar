;; access-control.clar
;; Provides read-only functions to check subscriber status

(define-constant ERR_INVALID_SUBSCRIBER (err u200))
(define-constant ERR_INVALID_PLAN (err u201))
(define-constant ERR_INVALID_TOKEN (err u202))

;; Import from other contracts
(define-read-only (get-subscription-expiry (subscriber principal) (plan-id uint))
  (contract-call? .subscription-manager get-expiry subscriber plan-id))

;; Check if a user is an active subscriber to a plan
(define-read-only (is-active-subscriber? (subscriber principal) (plan-id uint))
  (let ((expiry (unwrap! (get-subscription-expiry subscriber plan-id) false)))
    (> expiry block-height)))

;; Get all active subscriptions for a subscriber
(define-read-only (get-active-subscriptions (subscriber principal))
  (let ((subscriptions (unwrap! (contract-call? .subscription-manager get-all-subscriptions subscriber) (list))))
    (filter is-active-subscription subscriptions)))

;; Helper function to filter active subscriptions
(define-private (is-active-subscription (subscription {plan-id: uint, expiry: uint}))
  (> (get expiry subscription) block-height))

;; Check if a contract can access premium content by verifying the caller is an active subscriber
(define-read-only (can-access-premium-content (subscriber principal) (plan-id uint))
  (and 
    (contract-call? .admin is-platform-active)
    (is-active-subscriber? subscriber plan-id)))

;; Get time remaining on subscription in blocks
(define-read-only (get-remaining-blocks (subscriber principal) (plan-id uint))
  (let ((expiry (unwrap! (get-subscription-expiry subscriber plan-id) u0)))
    (if (> expiry block-height)
      (- expiry block-height)
      u0)))

;; Check if a plan is active
(define-read-only (is-plan-active (plan-id uint))
  (contract-call? .plan-manager is-plan-active plan-id))

;; Get details about a subscription including expiry and plan details
(define-read-only (get-subscription-details (subscriber principal) (plan-id uint))
  (let (
    (expiry (unwrap! (get-subscription-expiry subscriber plan-id) u0))
    (plan (unwrap! (contract-call? .plan-manager get-plan plan-id) none))
  )
    (merge plan {expiry: expiry})))