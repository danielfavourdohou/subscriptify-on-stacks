;; admin.clar
;; Handles administrative functions for the subscription platform

;; Use SIP-010 trait from mock-traits
(use-trait sip010-trait .mock-traits.sip010-trait)

;; Implement admin-trait
(impl-trait .mock-traits.admin-trait)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_ALREADY_PAUSED (err u101))
(define-constant ERR_ALREADY_ACTIVE (err u102))
(define-constant ERR_PAUSED (err u103))
(define-constant ERR_ZERO_AMOUNT (err u104))

;; Track if the entire platform is paused
(define-data-var platform-paused bool false)

;; Admin fee percentage (in basis points, 1000 = 10%)
(define-data-var admin-fee-bps uint u500)

;; Fee collection address
(define-data-var fee-address principal CONTRACT_OWNER)

;; Check if caller is the contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender CONTRACT_OWNER))

;; Pause the entire platform
(define-public (pause-platform)
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (not (var-get platform-paused)) ERR_ALREADY_PAUSED)
    (ok (var-set platform-paused true))))

;; Unpause the entire platform
(define-public (unpause-platform)
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (var-get platform-paused) ERR_ALREADY_ACTIVE)
    (ok (var-set platform-paused false))))

;; Check if platform is active
(define-read-only (is-platform-active)
  (ok (not (var-get platform-paused))))

;; Update admin fee (in basis points)
(define-public (set-admin-fee-bps (new-fee-bps uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    ;; Ensure fee is reasonable (max 20%)
    (asserts! (<= new-fee-bps u2000) (err u105))
    (ok (var-set admin-fee-bps new-fee-bps))))

;; Get current admin fee (in basis points)
(define-read-only (get-admin-fee-bps)
  (var-get admin-fee-bps))

;; Update fee collection address
(define-public (set-fee-address (new-address principal))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (ok (var-set fee-address new-address))))

;; Get current fee collection address
(define-read-only (get-fee-address)
  (ok (var-get fee-address)))

;; Calculate admin fee amount from a total payment
(define-read-only (calculate-admin-fee (payment-amount uint))
  (ok (/ (* payment-amount (var-get admin-fee-bps)) u10000)))

;; Withdraw available STX fees to the fee address
(define-public (withdraw-stx-fees (amount uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)
    (as-contract (stx-transfer? amount tx-sender (var-get fee-address)))))

;; Emergency function to recover any SIP-010 tokens sent to this contract
(define-public (recover-tokens (token-contract <sip010-trait>) (amount uint))
  (begin
    (asserts! (is-contract-owner) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_ZERO_AMOUNT)
    (as-contract
      (contract-call? token-contract transfer
        amount
        tx-sender
        (var-get fee-address)
        none))))