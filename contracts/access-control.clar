;; access-control.clar
;; Provides read-only functions to check subscriber status

;; Use traits from mock-traits
(use-trait admin-trait .mock-traits.admin-trait)
(use-trait subscription-manager-trait .mock-traits.subscription-manager-trait)
(use-trait plan-manager-trait .mock-traits.plan-manager-trait)

(define-constant ERR_INVALID_SUBSCRIBER (err u200))
(define-constant ERR_INVALID_PLAN (err u201))
(define-constant ERR_INVALID_TOKEN (err u202))

;; Import from other contracts - mock implementation for now
(define-read-only (get-subscription-expiry (subscriber principal) (plan-id uint))
  (ok u0))

;; Check if a user is an active subscriber to a plan
(define-read-only (is-active-subscriber? (subscriber principal) (plan-id uint))
  (let ((expiry (unwrap! (get-subscription-expiry subscriber plan-id) false)))
    (> expiry burn-block-height)))

;; Get all active subscriptions for a subscriber - mock implementation for now
(define-read-only (get-active-subscriptions (subscriber principal))
  (list))

;; Helper function to filter active subscriptions
(define-private (is-active-subscription (subscription {plan-id: uint, expiry: uint}))
  (> (get expiry subscription) burn-block-height))

;; Check if a contract can access premium content by verifying the caller is an active subscriber
(define-read-only (can-access-premium-content (subscriber principal) (plan-id uint))
  (is-active-subscriber? subscriber plan-id))

;; Get time remaining on subscription in blocks
(define-read-only (get-remaining-blocks (subscriber principal) (plan-id uint))
  (let ((expiry (unwrap! (get-subscription-expiry subscriber plan-id) u0)))
    (if (> expiry burn-block-height)
      (- expiry burn-block-height)
      u0)))

;; Check if a plan is active - mock implementation for now
(define-read-only (is-plan-active (plan-id uint))
  true)

;; Get details about a subscription including expiry and plan details - mock implementation for now
(define-read-only (get-subscription-details (subscriber principal) (plan-id uint))
  {
    creator: 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM,
    name: "Mock Plan",
    description: "Mock Description",
    price: u1000,
    period: u144,
    token-type: u0,
    token-contract: none,
    active: true,
    created-at: u0,
    expiry: u0
  })