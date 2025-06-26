;; plan-manager.clar
;; Manages subscription plans configuration

;; Implement plan-manager-trait
(impl-trait .mock-traits.plan-manager-trait)

;; Use admin-trait
(use-trait admin-trait .mock-traits.admin-trait)

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
    ;; Check platform is active - skip for now
    ;; (asserts! (unwrap! (contract-call? .admin is-platform-active) false) (err u406))

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
        created-at: burn-block-height
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
    ;; Check platform is active - skip for now
    ;; (asserts! (unwrap! (contract-call? .admin is-platform-active) false) (err u406))

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

    ;; Check platform is active - skip for now
    ;; (asserts! (unwrap! (contract-call? .admin is-platform-active) false) (err u406))

    ;; Check it's currently paused
    (asserts! (not (get active plan)) (err u410))

    ;; Update status
    (map-set plans plan-id (merge plan {active: true}))
    (ok plan-id)))

;; Get plan details
(define-read-only (get-plan (plan-id uint))
  (ok (map-get? plans plan-id)))

;; Check if a plan is active
(define-read-only (is-plan-active (plan-id uint))
  (match (map-get? plans plan-id)
    plan (ok (get active plan))
    (ok false)))

;; Get total number of plans
(define-read-only (get-plan-count)
  (var-get last-plan-id))

;; Get a single plan with ID and details
(define-read-only (get-plan-with-id (plan-id uint))
  {id: plan-id, plan: (map-get? plans plan-id)})

;; Get multiple plans by ID range - limited to 10 plans at a time
(define-read-only (get-plans-by-range (start-id uint) (end-id uint))
  (let
    (
      (id1 (if (<= start-id end-id) start-id u0))
      (id2 (if (and (<= (+ start-id u1) end-id) (>= (+ start-id u1) u1)) (+ start-id u1) u0))
      (id3 (if (and (<= (+ start-id u2) end-id) (>= (+ start-id u2) u1)) (+ start-id u2) u0))
      (id4 (if (and (<= (+ start-id u3) end-id) (>= (+ start-id u3) u1)) (+ start-id u3) u0))
      (id5 (if (and (<= (+ start-id u4) end-id) (>= (+ start-id u4) u1)) (+ start-id u4) u0))
      (id6 (if (and (<= (+ start-id u5) end-id) (>= (+ start-id u5) u1)) (+ start-id u5) u0))
      (id7 (if (and (<= (+ start-id u6) end-id) (>= (+ start-id u6) u1)) (+ start-id u6) u0))
      (id8 (if (and (<= (+ start-id u7) end-id) (>= (+ start-id u7) u1)) (+ start-id u7) u0))
      (id9 (if (and (<= (+ start-id u8) end-id) (>= (+ start-id u8) u1)) (+ start-id u8) u0))
      (id10 (if (and (<= (+ start-id u9) end-id) (>= (+ start-id u9) u1)) (+ start-id u9) u0))
      (initial-result (list))
      (result1 (if (> id1 u0) (append initial-result (get-plan-with-id id1)) initial-result))
      (result2 (if (> id2 u0) (append result1 (get-plan-with-id id2)) result1))
      (result3 (if (> id3 u0) (append result2 (get-plan-with-id id3)) result2))
      (result4 (if (> id4 u0) (append result3 (get-plan-with-id id4)) result3))
      (result5 (if (> id5 u0) (append result4 (get-plan-with-id id5)) result4))
      (result6 (if (> id6 u0) (append result5 (get-plan-with-id id6)) result5))
      (result7 (if (> id7 u0) (append result6 (get-plan-with-id id7)) result6))
      (result8 (if (> id8 u0) (append result7 (get-plan-with-id id8)) result7))
      (result9 (if (> id9 u0) (append result8 (get-plan-with-id id9)) result8))
      (result10 (if (> id10 u0) (append result9 (get-plan-with-id id10)) result9))
    )
    result10
  ))