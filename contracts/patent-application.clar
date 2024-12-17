;; Patent Application Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u403))

(define-data-var patent-office principal tx-sender)

(define-map patent-applications
  { application-id: uint }
  {
    patent-id: uint,
    applicant: principal,
    status: (string-ascii 20),
    review-count: uint,
    approved-count: uint
  }
)

(define-data-var last-application-id uint u0)

(define-public (submit-application (patent-id uint))
  (let
    (
      (application-id (+ (var-get last-application-id) u1))
    )
    (map-set patent-applications
      { application-id: application-id }
      {
        patent-id: patent-id,
        applicant: tx-sender,
        status: "pending",
        review-count: u0,
        approved-count: u0
      }
    )
    (var-set last-application-id application-id)
    (ok application-id)
  )
)

(define-public (update-application-status (application-id uint) (new-status (string-ascii 20)))
  (let
    (
      (application (unwrap! (map-get? patent-applications { application-id: application-id }) (err u404)))
    )
    (asserts! (is-eq tx-sender (var-get patent-office)) err-unauthorized)
    (ok (map-set patent-applications
      { application-id: application-id }
      (merge application { status: new-status })
    ))
  )
)

(define-read-only (get-application (application-id uint))
  (ok (unwrap! (map-get? patent-applications { application-id: application-id }) (err u404)))
)

(define-public (set-patent-office (new-office principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set patent-office new-office))
  )
)

(define-read-only (get-patent-office)
  (ok (var-get patent-office))
)
