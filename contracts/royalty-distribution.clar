;; c

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u403))

(define-map royalty-settings
{ patent-id: uint }
{
  inventor: principal,
  royalty-rate: uint,
  total-royalties: uint
}
)

(define-map royalty-payments
{ patent-id: uint, user: principal }
{ amount: uint }
)

(define-public (set-royalty-rate (patent-id uint) (royalty-rate uint))
(let
  (
    (current-settings (default-to { inventor: tx-sender, royalty-rate: u0, total-royalties: u0 }
                                 (map-get? royalty-settings { patent-id: patent-id })))
  )
  (asserts! (is-eq tx-sender (get inventor current-settings)) err-unauthorized)
  (ok (map-set royalty-settings
    { patent-id: patent-id }
    (merge current-settings { royalty-rate: royalty-rate })
  ))
)
)

(define-public (pay-royalty (patent-id uint) (amount uint))
(let
  (
    (settings (unwrap! (map-get? royalty-settings { patent-id: patent-id }) err-not-found))
    (royalty-amount (* amount (get royalty-rate settings)))
  )
  (try! (stx-transfer? royalty-amount tx-sender (get inventor settings)))
  (map-set royalty-settings
    { patent-id: patent-id }
    (merge settings { total-royalties: (+ (get total-royalties settings) royalty-amount) })
  )
  (let
    (
      (user-payment (default-to { amount: u0 } (map-get? royalty-payments { patent-id: patent-id, user: tx-sender })))
    )
    (map-set royalty-payments
      { patent-id: patent-id, user: tx-sender }
      { amount: (+ (get amount user-payment) royalty-amount) }
    )
  )
  (ok royalty-amount)
)
)

(define-read-only (get-royalty-settings (patent-id uint))
(ok (unwrap! (map-get? royalty-settings { patent-id: patent-id }) err-not-found))
)

(define-read-only (get-user-royalty-payments (patent-id uint) (user principal))
(ok (get amount (default-to { amount: u0 } (map-get? royalty-payments { patent-id: patent-id, user: user }))))
)

