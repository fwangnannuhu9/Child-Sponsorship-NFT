(define-non-fungible-token child-sponsorship-nft uint)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-wrong-commission (err u103))
(define-constant err-listing-exists (err u104))
(define-constant err-nft-mint-error (err u105))
(define-constant err-contract-locked (err u106))
(define-constant err-child-not-found (err u107))
(define-constant err-insufficient-payment (err u108))
(define-constant err-payment-not-due (err u109))
(define-constant err-already-sponsored (err u110))
(define-constant err-insufficient-emergency-fund (err u111))
(define-constant err-invalid-emergency-request (err u112))
(define-constant err-emergency-request-exists (err u113))
(define-constant err-emergency-request-not-found (err u114))
(define-constant err-emergency-request-not-approved (err u115))

(define-data-var last-token-id uint u0)
(define-data-var contract-locked bool false)
(define-data-var emergency-fund-balance uint u0)
(define-data-var last-emergency-request-id uint u0)

(define-map children-registry
    {child-id: uint}
    {
        name: (string-ascii 50),
        age: uint,
        location: (string-ascii 100),
        education-level: (string-ascii 30),
        monthly-support-needed: uint,
        sponsor: (optional principal),
        created-at: uint,
        is-active: bool
    }
)

(define-map sponsorship-payments
    {token-id: uint, payment-number: uint}
    {
        amount: uint,
        paid-at: uint,
        sponsor: principal,
        status: (string-ascii 10)
    }
)

(define-map progress-updates
    {child-id: uint, update-id: uint}
    {
        title: (string-ascii 100),
        description: (string-ascii 500),
        education-score: uint,
        health-score: uint,
        updated-at: uint,
        verified-by: principal
    }
)

(define-map child-metrics
    {child-id: uint}
    {
        total-payments-received: uint,
        last-payment-date: uint,
        next-payment-due: uint,
        total-updates: uint,
        avg-education-score: uint,
        avg-health-score: uint
    }
)

(define-map token-metadata
    {token-id: uint}
    {
        child-id: uint,
        sponsorship-start: uint,
        monthly-amount: uint,
        total-committed: uint,
        payments-made: uint
    }
)

(define-map emergency-fund-contributions
    {contributor: principal}
    {
        total-contributed: uint,
        last-contribution: uint,
        contribution-count: uint
    }
)

(define-map emergency-requests
    {request-id: uint}
    {
        child-id: uint,
        requested-amount: uint,
        urgency-level: uint,
        description: (string-ascii 500),
        requested-by: principal,
        requested-at: uint,
        status: (string-ascii 20),
        approved-by: (optional principal),
        approved-at: (optional uint),
        disbursed-at: (optional uint)
    }
)

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (token-id uint))
    (ok none)
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? child-sponsorship-nft token-id))
)

(define-read-only (get-child-info (child-id uint))
    (ok (map-get? children-registry {child-id: child-id}))
)

(define-read-only (get-sponsorship-metadata (token-id uint))
    (ok (map-get? token-metadata {token-id: token-id}))
)

(define-read-only (get-child-metrics (child-id uint))
    (ok (map-get? child-metrics {child-id: child-id}))
)

(define-read-only (get-payment-info (token-id uint) (payment-number uint))
    (ok (map-get? sponsorship-payments {token-id: token-id, payment-number: payment-number}))
)

(define-read-only (get-progress-update (child-id uint) (update-id uint))
    (ok (map-get? progress-updates {child-id: child-id, update-id: update-id}))
)

(define-read-only (get-emergency-fund-balance)
    (ok (var-get emergency-fund-balance))
)

(define-read-only (get-emergency-request (request-id uint))
    (ok (map-get? emergency-requests {request-id: request-id}))
)

(define-read-only (get-contributor-stats (contributor principal))
    (ok (map-get? emergency-fund-contributions {contributor: contributor}))
)

(define-read-only (is-payment-due (token-id uint))
    (let (
        (metadata (unwrap! (map-get? token-metadata {token-id: token-id}) (err err-listing-not-found)))
        (child-id (get child-id metadata))
        (metrics (unwrap! (map-get? child-metrics {child-id: child-id}) (err err-child-not-found)))
        (next-due (get next-payment-due metrics))
        (current-height stacks-block-height)
    )
        (ok (>= current-height next-due))
    )
)

(define-public (register-child (name (string-ascii 50)) (age uint) (location (string-ascii 100)) 
                              (education-level (string-ascii 30)) (monthly-support uint))
    (let (
        (child-id (+ (var-get last-token-id) u1))
        (current-height stacks-block-height)
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (var-get contract-locked)) err-contract-locked)
        
        (map-set children-registry
            {child-id: child-id}
            {
                name: name,
                age: age,
                location: location,
                education-level: education-level,
                monthly-support-needed: monthly-support,
                sponsor: none,
                created-at: current-height,
                is-active: true
            }
        )
        
        (map-set child-metrics
            {child-id: child-id}
            {
                total-payments-received: u0,
                last-payment-date: u0,
                next-payment-due: u0,
                total-updates: u0,
                avg-education-score: u50,
                avg-health-score: u50
            }
        )
        
        (var-set last-token-id child-id)
        (ok child-id)
    )
)

(define-public (sponsor-child (child-id uint) (commitment-months uint))
    (let (
        (token-id (+ (var-get last-token-id) u1))
        (child-info (unwrap! (map-get? children-registry {child-id: child-id}) err-child-not-found))
        (monthly-amount (get monthly-support-needed child-info))
        (total-commitment (* monthly-amount commitment-months))
        (current-height stacks-block-height)
        (next-payment (+ current-height u144))
    )
        (asserts! (is-none (get sponsor child-info)) err-already-sponsored)
        (asserts! (get is-active child-info) err-child-not-found)
        (asserts! (>= (stx-get-balance tx-sender) total-commitment) err-insufficient-payment)
        
        (try! (stx-transfer? total-commitment tx-sender (as-contract tx-sender)))
        (try! (nft-mint? child-sponsorship-nft token-id tx-sender))
        
        (map-set children-registry
            {child-id: child-id}
            (merge child-info {sponsor: (some tx-sender)})
        )
        
        (map-set token-metadata
            {token-id: token-id}
            {
                child-id: child-id,
                sponsorship-start: current-height,
                monthly-amount: monthly-amount,
                total-committed: total-commitment,
                payments-made: u0
            }
        )
        
        (map-set child-metrics
            {child-id: child-id}
            (merge (default-to 
                {total-payments-received: u0, last-payment-date: u0, next-payment-due: next-payment, 
                 total-updates: u0, avg-education-score: u50, avg-health-score: u50}
                (map-get? child-metrics {child-id: child-id}))
                {next-payment-due: next-payment}
            )
        )
        
        (var-set last-token-id token-id)
        (ok token-id)
    )
)

(define-public (make-monthly-payment (token-id uint))
    (let (
        (metadata (unwrap! (map-get? token-metadata {token-id: token-id}) err-listing-not-found))
        (child-id (get child-id metadata))
        (monthly-amount (get monthly-amount metadata))
        (payments-made (get payments-made metadata))
        (metrics (unwrap! (map-get? child-metrics {child-id: child-id}) err-child-not-found))
        (current-height stacks-block-height)
        (payment-number (+ payments-made u1))
    )
        (asserts! (is-eq (some tx-sender) (nft-get-owner? child-sponsorship-nft token-id)) err-not-token-owner)
        (asserts! (>= current-height (get next-payment-due metrics)) err-payment-not-due)
        
        (map-set sponsorship-payments
            {token-id: token-id, payment-number: payment-number}
            {
                amount: monthly-amount,
                paid-at: current-height,
                sponsor: tx-sender,
                status: "completed"
            }
        )
        
        (map-set token-metadata
            {token-id: token-id}
            (merge metadata {payments-made: payment-number})
        )
        
        (map-set child-metrics
            {child-id: child-id}
            (merge metrics {
                total-payments-received: (+ (get total-payments-received metrics) monthly-amount),
                last-payment-date: current-height,
                next-payment-due: (+ current-height u4320)
            })
        )
        
        (ok payment-number)
    )
)

(define-public (add-progress-update (child-id uint) (title (string-ascii 100)) 
                                  (description (string-ascii 500)) (education-score uint) (health-score uint))
    (let (
        (child-info (unwrap! (map-get? children-registry {child-id: child-id}) err-child-not-found))
        (metrics (unwrap! (map-get? child-metrics {child-id: child-id}) err-child-not-found))
        (update-id (+ (get total-updates metrics) u1))
        (current-height stacks-block-height)
        (new-avg-education (/ (+ (* (get avg-education-score metrics) (get total-updates metrics)) education-score) update-id))
        (new-avg-health (/ (+ (* (get avg-health-score metrics) (get total-updates metrics)) health-score) update-id))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= education-score u100) err-wrong-commission)
        (asserts! (<= health-score u100) err-wrong-commission)
        
        (map-set progress-updates
            {child-id: child-id, update-id: update-id}
            {
                title: title,
                description: description,
                education-score: education-score,
                health-score: health-score,
                updated-at: current-height,
                verified-by: tx-sender
            }
        )
        
        (map-set child-metrics
            {child-id: child-id}
            (merge metrics {
                total-updates: update-id,
                avg-education-score: new-avg-education,
                avg-health-score: new-avg-health
            })
        )
        
        (ok update-id)
    )
)

(define-public (contribute-to-emergency-fund (amount uint))
    (let (
        (current-balance (var-get emergency-fund-balance))
        (current-height stacks-block-height)
        (contributor-stats (default-to 
            {total-contributed: u0, last-contribution: u0, contribution-count: u0}
            (map-get? emergency-fund-contributions {contributor: tx-sender})
        ))
    )
        (asserts! (> amount u0) err-insufficient-payment)
        (asserts! (>= (stx-get-balance tx-sender) amount) err-insufficient-payment)
        
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (var-set emergency-fund-balance (+ current-balance amount))
        
        (map-set emergency-fund-contributions
            {contributor: tx-sender}
            {
                total-contributed: (+ (get total-contributed contributor-stats) amount),
                last-contribution: current-height,
                contribution-count: (+ (get contribution-count contributor-stats) u1)
            }
        )
        
        (ok amount)
    )
)

(define-public (request-emergency-funding (child-id uint) (amount uint) (urgency-level uint) (description (string-ascii 500)))
    (let (
        (child-info (unwrap! (map-get? children-registry {child-id: child-id}) err-child-not-found))
        (request-id (+ (var-get last-emergency-request-id) u1))
        (current-height stacks-block-height)
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (get is-active child-info) err-child-not-found)
        (asserts! (> amount u0) err-invalid-emergency-request)
        (asserts! (<= urgency-level u5) err-invalid-emergency-request)
        (asserts! (<= amount (var-get emergency-fund-balance)) err-insufficient-emergency-fund)
        
        (map-set emergency-requests
            {request-id: request-id}
            {
                child-id: child-id,
                requested-amount: amount,
                urgency-level: urgency-level,
                description: description,
                requested-by: tx-sender,
                requested-at: current-height,
                status: "pending",
                approved-by: none,
                approved-at: none,
                disbursed-at: none
            }
        )
        
        (var-set last-emergency-request-id request-id)
        (ok request-id)
    )
)

(define-public (approve-emergency-request (request-id uint))
    (let (
        (request-info (unwrap! (map-get? emergency-requests {request-id: request-id}) err-emergency-request-not-found))
        (current-height stacks-block-height)
        (requested-amount (get requested-amount request-info))
        (current-balance (var-get emergency-fund-balance))
    )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status request-info) "pending") err-invalid-emergency-request)
        (asserts! (<= requested-amount current-balance) err-insufficient-emergency-fund)
        
        (var-set emergency-fund-balance (- current-balance requested-amount))
        
        (map-set emergency-requests
            {request-id: request-id}
            (merge request-info {
                status: "approved",
                approved-by: (some tx-sender),
                approved-at: (some current-height),
                disbursed-at: (some current-height)
            })
        )
        
        (ok requested-amount)
    )
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (asserts! (is-eq (some sender) (nft-get-owner? child-sponsorship-nft token-id)) err-not-token-owner)
        (try! (nft-transfer? child-sponsorship-nft token-id sender recipient))
        (ok true)
    )
)

(define-public (set-contract-locked (locked bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-locked locked)
        (ok true)
    )
)

(define-read-only (get-contract-locked)
    (ok (var-get contract-locked))
)
