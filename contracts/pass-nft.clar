;; pass-nft.clar
;; Implements SIP-009 NFT standard for subscription passes

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_NOT_FOUND (err u301))
(define-constant ERR_ALREADY_MINTED (err u302))
(define-constant ERR_WRONG_OWNER (err u303))

;; Track token IDs
(define-data-var last-token-id uint u0)

;; NFT ownership
(define-map token-owners uint principal)

;; Metadata for each token
(define-map token-metadata uint {plan-id: uint, expiry: uint})

;; Map from (subscriber, plan) to token ID
(define-map subscription-to-token {subscriber: principal, plan-id: uint} uint)

;; Only subscription manager can mint and burn tokens
(define-private (is-contract-owner-or-subscription-manager)
  (or (is-eq tx-sender CONTRACT_OWNER)
      (is-eq tx-sender 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.subscription-manager)))

;; Get the last token ID
(define-read-only (get-last-token-id)
  (var-get last-token-id))

;; Get token URI (SIP-009)
(define-read-only (get-token-uri (token-id uint))
  (ok (some (concat "https://subscriptify.io/metadata/" (uint-to-ascii token-id)))))

;; Get total supply of tokens (SIP-009)
(define-read-only (get-total-supply)
  (ok (var-get last-token-id)))

;; Get token owner (SIP-009)
(define-read-only (get-owner (token-id uint))
  (ok (map-get? token-owners token-id)))

;; Mint a new subscription pass NFT
(define-public (mint (subscriber principal) (plan-id uint) (expiry uint))
  (begin
    (asserts! (is-contract-owner-or-subscription-manager) ERR_NOT_AUTHORIZED)
    (let ((token-id (+ (var-get last-token-id) u1))
          (subscription-key {subscriber: subscriber, plan-id: plan-id}))
      ;; Check if user already has a pass for this plan
      (asserts! (is-none (map-get? subscription-to-token subscription-key)) ERR_ALREADY_MINTED)
      
      ;; Update state
      (var-set last-token-id token-id)
      (map-set token-owners token-id subscriber)
      (map-set token-metadata token-id {plan-id: plan-id, expiry: expiry})
      (map-set subscription-to-token subscription-key token-id)
      
      (ok token-id))))

;; Burn a subscription pass NFT
(define-public (burn (subscriber principal) (plan-id uint))
  (begin
    (asserts! (is-contract-owner-or-subscription-manager) ERR_NOT_AUTHORIZED)
    (let ((subscription-key {subscriber: subscriber, plan-id: plan-id})
          (token-id (unwrap! (map-get? subscription-to-token subscription-key) ERR_NOT_FOUND)))
      
      ;; Verify ownership
      (asserts! (is-eq (unwrap! (map-get? token-owners token-id) none) subscriber) ERR_WRONG_OWNER)
      
      ;; Update state
      (map-delete token-owners token-id)
      (map-delete token-metadata token-id)
      (map-delete subscription-to-token subscription-key)
      
      (ok token-id))))

;; Update expiry date of an existing NFT
(define-public (update-expiry (subscriber principal) (plan-id uint) (new-expiry uint))
  (begin
    (asserts! (is-contract-owner-or-subscription-manager) ERR_NOT_AUTHORIZED)
    (let ((subscription-key {subscriber: subscriber, plan-id: plan-id})
          (token-id (unwrap! (map-get? subscription-to-token subscription-key) ERR_NOT_FOUND)))
      
      ;; Update metadata
      (map-set token-metadata token-id 
        (merge (unwrap! (map-get? token-metadata token-id) (err u304))
               {expiry: new-expiry}))
      
      (ok token-id))))

;; Get token metadata
(define-read-only (get-token-metadata (token-id uint))
  (map-get? token-metadata token-id))

;; Get token ID for a subscription if it exists
(define-read-only (get-token-for-subscription (subscriber principal) (plan-id uint))
  (map-get? subscription-to-token {subscriber: subscriber, plan-id: plan-id}))

;; SIP-009: Transfer function (disabled for subscription passes)
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (err u305)) ;; Subscription passes are non-transferable