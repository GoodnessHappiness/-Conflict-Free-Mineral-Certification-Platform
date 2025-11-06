;; Conflict-Free Mineral Certification Platform Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-mine-not-whitelisted (err u105))
(define-constant err-already-voted (err u106))
(define-constant err-insufficient-votes (err u107))
(define-constant err-invalid-grade (err u108))
(define-constant err-contract-paused (err u109))
(define-constant err-already-endorsed (err u110))

(define-data-var last-token-id uint u0)
(define-data-var last-mine-id uint u0)
(define-data-var voting-threshold uint u3)
(define-data-var contract-paused bool false)
(define-data-var certification-fee uint u1000000)

(define-map mines uint {
    owner: principal,
    latitude: int,
    longitude: int,
    name: (string-ascii 50),
    whitelisted: bool,
    flagged: bool,
    flag-votes: uint,
    endorsement-count: uint
})

(define-map mineral-certificates uint {
    owner: principal,
    mine-id: uint,
    mineral-type: (string-ascii 30),
    quantity: uint,
    certification-date: uint,
    origin-verified: bool,
    transfer-history: (list 10 principal),
    quality-grade: (optional (string-ascii 3)),
    graded-by: (optional principal),
    grade-date: (optional uint),
    retired: bool
})

(define-map mine-whitelist uint bool)
(define-map flag-votes { mine-id: uint, voter: principal } bool)
(define-map authorized-certifiers principal bool)
(define-map authorized-graders principal bool)
(define-map mine-endorsements { mine-id: uint, endorser: principal } bool)

(define-public (get-last-token-id)
    (ok (var-get last-token-id)))

(define-public (get-token-uri (token-id uint))
    (ok none))

(define-public (owner-of (token-id uint))
    (ok (get owner (map-get? mineral-certificates token-id))))

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (let ((token (unwrap! (map-get? mineral-certificates token-id) err-not-found)))
        (asserts! (is-eq tx-sender sender) err-unauthorized)
        (asserts! (is-eq sender (get owner token)) err-unauthorized)
        (asserts! (not (get retired token)) err-unauthorized)
        (map-set mineral-certificates token-id
            (merge token {
                owner: recipient,
                transfer-history: (match (as-max-len?
                    (append (get transfer-history token) recipient) u10)
                    new-history new-history
                    (get transfer-history token))
            }))
        (print { action: "transfer", token-id: token-id, from: sender, to: recipient })
        (ok true)))

(define-public (register-mine (latitude int) (longitude int) (name (string-ascii 50)))
    (let ((mine-id (+ (var-get last-mine-id) u1)))
        (map-set mines mine-id {
            owner: tx-sender,
            latitude: latitude,
            longitude: longitude,
            name: name,
            whitelisted: false,
            flagged: false,
            flag-votes: u0,
            endorsement-count: u0
        })
        (var-set last-mine-id mine-id)
        (print { action: "mine-registered", mine-id: mine-id, owner: tx-sender })
        (ok mine-id)))

(define-public (add-to-whitelist (mine-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? mines mine-id)) err-not-found)
        (map-set mine-whitelist mine-id true)
        (map-set mines mine-id 
            (merge (unwrap-panic (map-get? mines mine-id)) { whitelisted: true }))
        (print { action: "mine-whitelisted", mine-id: mine-id })
        (ok true)))

(define-public (remove-from-whitelist (mine-id uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-some (map-get? mines mine-id)) err-not-found)
        (map-set mine-whitelist mine-id false)
        (map-set mines mine-id 
            (merge (unwrap-panic (map-get? mines mine-id)) { whitelisted: false }))
        (print { action: "mine-removed-from-whitelist", mine-id: mine-id })
        (ok true)))

(define-public (add-authorized-certifier (certifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-certifiers certifier true)
        (print { action: "certifier-authorized", certifier: certifier })
        (ok true)))

(define-public (remove-authorized-certifier (certifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-certifiers certifier false)
        (print { action: "certifier-removed", certifier: certifier })
        (ok true)))

(define-public (certify-mineral (mine-id uint) (mineral-type (string-ascii 30)) (quantity uint) (recipient principal))
     (let ((token-id (+ (var-get last-token-id) u1))
           (mine (unwrap! (map-get? mines mine-id) err-not-found))
           (fee (var-get certification-fee)))
         (asserts! (default-to false (map-get? authorized-certifiers tx-sender)) err-unauthorized)
         (asserts! (get whitelisted mine) err-mine-not-whitelisted)
         (asserts! (> quantity u0) err-invalid-amount)
         (asserts! (not (get flagged mine)) err-unauthorized)
         (try! (stx-transfer? fee tx-sender contract-owner))
         (map-set mineral-certificates token-id {
             owner: recipient,
             mine-id: mine-id,
             mineral-type: mineral-type,
             quantity: quantity,
             certification-date: stacks-block-height,
             origin-verified: true,
             transfer-history: (list recipient),
             quality-grade: none,
             graded-by: none,
             grade-date: none,
             retired: false
         })
         (var-set last-token-id token-id)
         (print {
             action: "mineral-certified",
             token-id: token-id,
             mine-id: mine-id,
             mineral-type: mineral-type,
             quantity: quantity,
             recipient: recipient
         })
         (ok token-id)))

(define-public (flag-mine (mine-id uint))
    (let ((mine (unwrap! (map-get? mines mine-id) err-not-found)))
        (asserts! (is-none (map-get? flag-votes { mine-id: mine-id, voter: tx-sender })) err-already-voted)
        (map-set flag-votes { mine-id: mine-id, voter: tx-sender } true)
        (let ((new-vote-count (+ (get flag-votes mine) u1)))
            (map-set mines mine-id
                (merge mine { flag-votes: new-vote-count }))
            (if (>= new-vote-count (var-get voting-threshold))
                (begin
                    (map-set mines mine-id
                        (merge mine { flagged: true, whitelisted: false }))
                    (map-set mine-whitelist mine-id false)
                    (print { action: "mine-flagged-and-removed", mine-id: mine-id, votes: new-vote-count }))
                (print { action: "mine-vote-recorded", mine-id: mine-id, votes: new-vote-count }))
            (ok new-vote-count))))

(define-public (endorse-mine (mine-id uint))
    (let ((mine (unwrap! (map-get? mines mine-id) err-not-found)))
        (asserts! (get whitelisted mine) err-mine-not-whitelisted)
        (asserts! (not (get flagged mine)) err-unauthorized)
        (asserts! (is-none (map-get? mine-endorsements { mine-id: mine-id, endorser: tx-sender })) err-already-endorsed)
        (map-set mine-endorsements { mine-id: mine-id, endorser: tx-sender } true)
        (let ((new-endorsement-count (+ (get endorsement-count mine) u1)))
            (map-set mines mine-id
                (merge mine { endorsement-count: new-endorsement-count }))
            (print { action: "mine-endorsed", mine-id: mine-id, endorser: tx-sender, endorsements: new-endorsement-count })
            (ok new-endorsement-count))))

(define-public (update-voting-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set voting-threshold new-threshold)
        (print { action: "voting-threshold-updated", threshold: new-threshold })
        (ok true)))

(define-public (authorize-grader (grader principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-graders grader true)
        (print { action: "grader-authorized", grader: grader })
        (ok true)))

(define-public (revoke-grader (grader principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set authorized-graders grader false)
        (print { action: "grader-revoked", grader: grader })
        (ok true)))

(define-public (assign-quality-grade (token-id uint) (grade (string-ascii 3)))
    (let ((token (unwrap! (map-get? mineral-certificates token-id) err-not-found)))
        (asserts! (default-to false (map-get? authorized-graders tx-sender)) err-unauthorized)
        (asserts! (or (is-eq grade "AAA") (is-eq grade "AA") (is-eq grade "A")
                      (is-eq grade "B") (is-eq grade "C")) err-invalid-grade)
        (map-set mineral-certificates token-id
            (merge token {
                quality-grade: (some grade),
                graded-by: (some tx-sender),
                grade-date: (some stacks-block-height)
            }))
        (print {
            action: "quality-grade-assigned",
            token-id: token-id,
            grade: grade,
            grader: tx-sender
        })
        (ok true)))
(define-public (pause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused true)
        (print { action: "contract-paused" })
        (ok true)))
(define-public (unpause-contract)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set contract-paused false)
        (print { action: "contract-unpaused" })
        (ok true)))

(define-public (transfer-mine-ownership (mine-id uint) (new-owner principal))
    (let ((mine (unwrap! (map-get? mines mine-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner mine)) err-unauthorized)
        (asserts! (not (is-eq new-owner (get owner mine))) err-unauthorized)
        (map-set mines mine-id (merge mine { owner: new-owner }))
        (print { action: "mine-ownership-transferred", mine-id: mine-id, from: tx-sender, to: new-owner })
        (ok true)))

(define-public (retire-certificate (token-id uint))
    (let ((token (unwrap! (map-get? mineral-certificates token-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner token)) err-unauthorized)
        (asserts! (not (get retired token)) err-unauthorized)
        (map-set mineral-certificates token-id
            (merge token { retired: true }))
        (print { action: "certificate-retired", token-id: token-id, owner: tx-sender })
        (ok true)))

(define-public (update-certification-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set certification-fee new-fee)
        (print { action: "certification-fee-updated", new-fee: new-fee })
        (ok true)))

(define-public (batch-transfer (token-ids (list 10 uint)) (recipients (list 10 principal)))
    (let ((transfers (map transfer-single token-ids recipients)))
        (asserts! (is-eq (len token-ids) (len recipients)) err-invalid-amount)
        (ok transfers)))

(define-private (transfer-single (token-id uint) (recipient principal))
    (match (map-get? mineral-certificates token-id)
        token (begin
            (asserts! (is-eq tx-sender (get owner token)) err-unauthorized)
            (map-set mineral-certificates token-id 
                (merge token { 
                    owner: recipient,
                    transfer-history: (match (as-max-len? 
                        (append (get transfer-history token) recipient) u10)
                        new-history new-history
                        (get transfer-history token))
                }))
            (print { action: "batch-transfer", token-id: token-id, to: recipient })
            (ok token-id))
        err-not-found))

(define-read-only (get-mine (mine-id uint))
    (map-get? mines mine-id))

(define-read-only (get-mineral-certificate (token-id uint))
    (map-get? mineral-certificates token-id))

(define-read-only (is-mine-whitelisted (mine-id uint))
    (default-to false (map-get? mine-whitelist mine-id)))

(define-read-only (is-certifier-authorized (certifier principal))
    (default-to false (map-get? authorized-certifiers certifier)))

(define-read-only (get-mine-flag-votes (mine-id uint))
    (match (map-get? mines mine-id)
        mine (get flag-votes mine)
        u0))

(define-read-only (has-user-voted (mine-id uint) (voter principal))
    (default-to false (map-get? flag-votes { mine-id: mine-id, voter: voter })))

(define-read-only (get-transfer-history (token-id uint))
    (match (map-get? mineral-certificates token-id)
        token (get transfer-history token)
        (list)))

(define-read-only (verify-mineral-origin (token-id uint))
    (match (map-get? mineral-certificates token-id)
        token (let ((mine (unwrap! (map-get? mines (get mine-id token)) false)))
                (and (get origin-verified token) 
                     (get whitelisted mine) 
                     (not (get flagged mine))))
        false))

(define-read-only (get-current-voting-threshold)
    (var-get voting-threshold))

(define-read-only (is-grader-authorized (grader principal))
    (default-to false (map-get? authorized-graders grader)))

(define-read-only (get-quality-grade (token-id uint))
    (match (map-get? mineral-certificates token-id)
        token (get quality-grade token)
        none))

(define-read-only (get-grading-info (token-id uint))
    (match (map-get? mineral-certificates token-id)
        token {
            quality-grade: (get quality-grade token),
            graded-by: (get graded-by token),
            grade-date: (get grade-date token)
        }
        { quality-grade: none, graded-by: none, grade-date: none }))

(define-read-only (has-quality-grade (token-id uint) (grade (string-ascii 3)))
    (match (get-quality-grade token-id)
        current-grade (is-eq current-grade grade)
        false))

(define-read-only (get-mine-endorsement-count (mine-id uint))
    (match (map-get? mines mine-id)
        mine (get endorsement-count mine)
        u0))

(define-read-only (has-user-endorsed (mine-id uint) (endorser principal))
    (default-to false (map-get? mine-endorsements { mine-id: mine-id, endorser: endorser })))

(map-set authorized-certifiers contract-owner true)
