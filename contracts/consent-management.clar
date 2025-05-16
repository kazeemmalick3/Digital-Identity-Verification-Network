;; Consent Management Contract
;; Controls data sharing permissions

;; Data Maps
(define-map consent-records
  { user: principal, data-consumer: principal }
  {
    attributes: (list 10 (string-utf8 50)),
    purpose: (string-utf8 200),
    expiration: uint,
    revoked: bool
  }
)

;; Constants
(define-constant err-not-authorized (err u100))
(define-constant err-already-exists (err u101))
(define-constant err-not-found (err u102))
(define-constant err-expired (err u103))

;; Read-only functions
(define-read-only (get-consent (user principal) (data-consumer principal))
  (map-get? consent-records { user: user, data-consumer: data-consumer })
)

(define-read-only (is-consent-valid (user principal) (data-consumer principal) (attribute (string-utf8 50)))
  (match (map-get? consent-records { user: user, data-consumer: data-consumer })
    consent-data
      (and
        (not (get revoked consent-data))
        (< block-height (get expiration consent-data))
        (is-some (index-of (get attributes consent-data) attribute))
      )
    false
  )
)

;; Public functions
(define-public (grant-consent
    (data-consumer principal)
    (attributes (list 10 (string-utf8 50)))
    (purpose (string-utf8 200))
    (expiration uint)
  )
  (let ((user tx-sender))
    (map-set consent-records
      { user: user, data-consumer: data-consumer }
      {
        attributes: attributes,
        purpose: purpose,
        expiration: expiration,
        revoked: false
      }
    )
    (ok true)
  )
)

(define-public (revoke-consent (data-consumer principal))
  (let ((user tx-sender))
    (match (map-get? consent-records { user: user, data-consumer: data-consumer })
      consent-data
        (begin
          (map-set consent-records
            { user: user, data-consumer: data-consumer }
            (merge consent-data { revoked: true })
          )
          (ok true)
        )
      err-not-found
    )
  )
)

(define-public (update-consent
    (data-consumer principal)
    (attributes (list 10 (string-utf8 50)))
    (purpose (string-utf8 200))
    (expiration uint)
  )
  (let ((user tx-sender))
    (match (map-get? consent-records { user: user, data-consumer: data-consumer })
      consent-data
        (begin
          (map-set consent-records
            { user: user, data-consumer: data-consumer }
            {
              attributes: attributes,
              purpose: purpose,
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
