;; math-time.clar
;; Utility functions for block time and expiry calculations

;; Constants for time calculations
(define-constant BLOCKS_PER_DAY u144)  ;; Approx 10 sec per block = 144 blocks per day
(define-constant BLOCKS_PER_WEEK (* BLOCKS_PER_DAY u7))
(define-constant BLOCKS_PER_MONTH (* BLOCKS_PER_DAY u30))
(define-constant BLOCKS_PER_YEAR (* BLOCKS_PER_DAY u365))

;; Convert days to blocks
(define-read-only (days-to-blocks (days uint))
  (* days BLOCKS_PER_DAY))

;; Convert weeks to blocks
(define-read-only (weeks-to-blocks (weeks uint))
  (* weeks BLOCKS_PER_WEEK))

;; Convert months to blocks
(define-read-only (months-to-blocks (months uint))
  (* months BLOCKS_PER_MONTH))

;; Convert years to blocks
(define-read-only (years-to-blocks (years uint))
  (* years BLOCKS_PER_YEAR))

;; Convert blocks to days (approximate)
(define-read-only (blocks-to-days (blocks uint))
  (/ blocks BLOCKS_PER_DAY))

;; Convert blocks to months (approximate)
(define-read-only (blocks-to-months (blocks uint))
  (/ blocks BLOCKS_PER_MONTH))

;; Get number of blocks remaining until a specific block height
(define-read-only (blocks-until (target-height uint))
  (if (> target-height block-height)
      (- target-height block-height)
      u0))

;; Get expiry block height for a given period in blocks
(define-read-only (calculate-expiry (period-blocks uint))
  (+ block-height period-blocks))

;; Check if a given expiry is valid (in the future)
(define-read-only (is-expiry-valid (expiry uint))
  (> expiry block