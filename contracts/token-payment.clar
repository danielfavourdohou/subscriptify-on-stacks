;; token-payment.clar
;; Handles SIP-010 token payments and allowances

;; Use SIP-010 trait from mock-traits
(use-trait sip010-trait .mock-traits.sip010-trait)

(define-constant ERR_INSUFFICIENT_ALLOWANCE (err u600))
(define-constant ERR_TRANSFER_FAILED (err u601))

;; Process token payment with a specified SIP-010 token
(define-public (process-token-payment
  (token-contract <sip010-trait>)
  (from principal)
  (to principal)
  (fee-address principal)
  (amount uint)
)
  (let (
        (fee-amount-response (unwrap! (contract-call? .admin calculate-admin-fee amount) (err u603)))
        (fee-amount fee-amount-response)
        (recipient-amount (- amount fee-amount))
       )

    ;; First check if we have enough allowance
    (asserts! (check-allowance token-contract from (as-contract tx-sender) amount)
              ERR_INSUFFICIENT_ALLOWANCE)

    ;; Transfer from sender to contract
    (asserts! (transfer-token token-contract from (as-contract tx-sender) amount)
              ERR_TRANSFER_FAILED)

    ;; Transfer to recipient
    (asserts! (as-contract (transfer-token token-contract tx-sender to recipient-amount))
              ERR_TRANSFER_FAILED)

    ;; Transfer fee
    (asserts! (as-contract (transfer-token token-contract tx-sender fee-address fee-amount))
              ERR_TRANSFER_FAILED)

    (ok true)))

;; Check if contract has enough allowance from user
(define-private (check-allowance (token-contract <sip010-trait>) (owner principal) (spender principal) (amount uint))
  (match (contract-call? token-contract get-allowance owner spender)
    ok-value (>= ok-value amount)
    err-value false))

;; Transfer tokens using SIP-010 interface
(define-private (transfer-token (token-contract <sip010-trait>) (from principal) (to principal) (amount uint))
  (is-ok (contract-call? token-contract transfer amount from to none)))

;; Transfer tokens from contract to recipient
(define-public (emergency-recover-tokens (token-contract <sip010-trait>) (recipient principal) (amount uint) (fee-address principal))
  (begin
    (asserts! (is-eq tx-sender fee-address) (err u602))
    (if (as-contract (transfer-token token-contract tx-sender recipient amount))
        (ok true)
        (err u604))))