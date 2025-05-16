;; Identity Provider Verification Contract
;; This contract validates and manages credential issuers in the network

;; Data Maps
(define-map approved-providers
  principal
  {
    name: (string-utf8 100),
    url: (string-utf8 100),
    active: bool,
    trust-score: uint,
    registration-time: uint
  }
)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-registered (err u102))

;; Read-only functions
(define-read-only (is-provider-approved (provider principal))
  (match (map-get? approved-providers provider)
    provider-data (ok (get active provider-data))
    (ok false)
  )
)

(define-read-only (get-provider-details (provider principal))
  (map-get? approved-providers provider)
)

;; Public functions
(define-public (register-provider (name (string-utf8 100)) (url (string-utf8 100)))
  (let ((provider tx-sender))
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-none (map-get? approved-providers provider)) err-already-registered)

    (map-set approved-providers
      provider
      {
        name: name,
        url: url,
        active: true,
        trust-score: u50,
        registration-time: block-height
      }
    )
    (ok true)
  )
)

(define-public (update-provider-status (provider principal) (active bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-some (map-get? approved-providers provider)) err-not-registered)

    (map-set approved-providers
      provider
      (merge (unwrap-panic (map-get? approved-providers provider)) { active: active })
    )
    (ok true)
  )
)

(define-public (update-trust-score (provider principal) (new-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (asserts! (is-some (map-get? approved-providers provider)) err-not-registered)

    (map-set approved-providers
      provider
      (merge (unwrap-panic (map-get? approved-providers provider)) { trust-score: new-score })
    )
    (ok true)
  )
)
