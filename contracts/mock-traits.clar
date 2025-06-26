;; mock-traits.clar
;; Contains trait definitions for all contracts to avoid circular dependencies

;; SIP-010 Fungible Token Trait
(define-trait sip010-trait
  (
    ;; Transfer from the caller to a new principal
    (transfer (uint principal principal (optional (buff 34))) (response bool uint))
    ;; Get the token balance of the specified principal
    (get-balance (principal) (response uint uint))
    ;; Get the allowance for a specified spender
    (get-allowance (principal principal) (response uint uint))
  )
)

;; NFT Trait
(define-trait nft-trait
  (
    ;; Last token ID, limited to uint range
    (get-last-token-id () (response uint uint))
    ;; URI for metadata associated with the token
    (get-token-uri (uint) (response (optional (string-ascii 256)) uint))
    ;; Gets the owner of the specified token ID
    (get-owner (uint) (response (optional principal) uint))
    ;; Transfer from the sender to a new principal
    (transfer (uint principal principal) (response bool uint))
    ;; Get the total number of tokens
    (get-total-supply () (response uint uint))
  )
)

;; Admin Trait
(define-trait admin-trait
  (
    ;; Check if platform is active
    (is-platform-active () (response bool uint))
    ;; Get fee address
    (get-fee-address () (response principal uint))
    ;; Calculate admin fee
    (calculate-admin-fee (uint) (response uint uint))
  )
)

;; Plan Manager Trait
(define-trait plan-manager-trait
  (
    ;; Get plan details
    (get-plan (uint) (response (optional (tuple (creator principal) (name (string-ascii 64)) (description (string-ascii 256)) (price uint) (period uint) (token-type uint) (token-contract (optional principal)) (active bool) (created-at uint))) uint))
    ;; Check if plan is active
    (is-plan-active (uint) (response bool uint))
  )
)

;; Subscription Manager Trait
(define-trait subscription-manager-trait
  (
    ;; Get subscription expiry
    (get-expiry (principal uint) (response uint uint))
    ;; Get all subscriptions
    (get-all-subscriptions (principal) (response (list 100 {plan-id: uint, expiry: uint}) uint))
  )
)

;; Pass NFT Trait
(define-trait pass-nft-trait
  (
    ;; Mint a new NFT
    (mint (principal uint uint) (response uint uint))
    ;; Burn an NFT
    (burn (principal uint) (response uint uint))
    ;; Update expiry
    (update-expiry (principal uint uint) (response uint uint))
  )
)
