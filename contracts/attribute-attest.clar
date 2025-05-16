;; Attribute Attestation Contract
;; Records verified identity claims

;; Data Maps
(define-map attestations
  { user: principal, attribute-id: (string-utf8 50) }
  {
    value: (string-utf8 200),
    issuer: principal,
    expiration: uint,
    revoked: bool
  }
)

;; Constants
(define-constant err-not-authorized (err u100))
(define-constant err-already-attested (err u101))
(define-constant err-not-found (err u102))
(define-constant err-expired (err u103))

;; Read-only functions
(define-read-only (get-attestation (user principal) (attribute-id (string-utf8 50)))
  (map-get? attestations { user: user, attribute-id: attribute-id })
)

(define-read-only (is-attestation-valid (user principal) (attribute-id (string-utf8 50)))
  (match (map-get? attestations { user: user, attribute-id: attribute-id })
    attestation-data
      (and
        (not (get revoked attestation-data))
        (< block-height (get expiration attestation-data))
      )
    false
  )
)

;; Public functions
(define-public (create-attestation
    (user principal)
    (attribute-id (string-utf8 50))
    (value (string-utf8 200))
    (expiration uint)
  )
  (let ((issuer tx-sender))
    ;; Check if issuer is an approved provider (would call identity-provider-verification contract)
    ;; For simplicity, we're not implementing the cross-contract call here

    (asserts! (is-none (map-get? attestations { user: user, attribute-id: attribute-id }))
              err-already-attested)

    (map-set attestations
      { user: user, attribute-id: attribute-id }
      {
        value: value,
        issuer: issuer,
        expiration: expiration,
        revoked: false
      }
    )
    (ok true)
  )
)

(define-public (revoke-attestation (user principal) (attribute-id (string-utf8 50)))
  (let ((issuer tx-sender))
    (match (map-get? attestations { user: user, attribute-id: attribute-id })
      attestation-data
        (begin
          (asserts! (is-eq issuer (get issuer attestation-data)) err-not-authorized)
          (map-set attestations
            { user: user, attribute-id: attribute-id }
            (merge attestation-data { revoked: true })
          )
          (ok true)
        )
      err-not-found
    )
  )
)

(define-public (update-attestation
    (user principal)
    (attribute-id (string-utf8 50))
    (value (string-utf8 200))
    (expiration uint)
  )
  (let ((issuer tx-sender))
    (match (map-get? attestations { user: user, attribute-id: attribute-id })
      attestation-data
        (begin
          (asserts! (is-eq issuer (get issuer attestation-data)) err-not-authorized)
          (map-set attestations
            { user: user, attribute-id: attribute-id }
            {
              value: value,
              issuer: issuer,
              expiration: expiration,
              revoked: false
            }
          )
          (ok true)
        )
      err-not-found
    )
  )
)
