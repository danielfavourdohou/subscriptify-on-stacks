;; token-payment.clar
;; Handles SIP-010 token payments and allowances

(define-constant ERR_INSUFFICIENT_ALLOWANCE (err u600))
(define-constant ERR_TRANSFER_FAILED (err u601))

;; Process token payment with a specified SIP-010 token
(define-public (process-token-payment 
  (token-contract principal)
  (from principal)
  (to principal)
  (fee-address principal)
  (amount uint)
)
  (let ((fee-amount (contract-call? .admin calculate-admin-fee amount))
        (recipient-amount (- amount fee-amount)))
    
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
    
    true))

;; Check if contract has enough allowance from user
(define-private (check-allowance (token-contract principal) (owner principal) (spender principal) (amount uint))
  (match (contract-call? token-contract get-allowance owner spender)
    allowance (>= allowance amount)
    false))

;; Transfer tokens using SIP-010 interface
(define-private (transfer-token (token-contract principal) (from principal) (to principal) (amount uint))
  (is-ok (contract-call? token-contract transfer amount from to none)))

;; Transfer tokens from contract to recipient
(define-public (emergency-recover-tokens (token-contract principal) (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (contract-call? .admin get-fee-address)) (err u602))
    (as-contract (transfer-token token-contract tx-sender recipient amount))))