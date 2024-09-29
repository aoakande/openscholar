;; OpenScholar Paper Submission Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-already-submitted (err u101))
(define-constant err-paper-not-found (err u102))

;; Define data variables
(define-data-var next-paper-id uint u0)

;; Define data maps
(define-map papers
  { paper-id: uint }
  {
    author: principal,
    title: (string-utf8 256),
    abstract: (string-utf8 1024),
    ipfs-hash: (string-ascii 46),
    timestamp: uint,
    status: (string-ascii 20)
  }
)

(define-map author-papers
  { author: principal }
  { paper-ids: (list 100 uint) }
)

;; Public functions

;; Submit a new paper
(define-public (submit-paper (title (string-utf8 256)) (abstract (string-utf8 1024)) (ipfs-hash (string-ascii 46)))
  (let
    (
      (paper-id (var-get next-paper-id))
      (author tx-sender)
    )
    (map-set papers
      { paper-id: paper-id }
      {
        author: author,
        title: title,
        abstract: abstract,
        ipfs-hash: ipfs-hash,
        timestamp: block-height,
        status: "submitted"
      }
    )
    (map-set author-papers
      { author: author }
      { paper-ids: (unwrap! (as-max-len? (append (default-to (list) (get paper-ids (map-get? author-papers { author: author }))) paper-id) u100) err-already-submitted) }
    )
    (var-set next-paper-id (+ paper-id u1))
    (ok paper-id)
  )
)

;; Get paper details
(define-read-only (get-paper (paper-id uint))
  (match (map-get? papers { paper-id: paper-id })
    paper (ok paper)
    (err err-paper-not-found)
  )
)

;; Get papers by author
(define-read-only (get-author-papers (author principal))
  (ok (get paper-ids (default-to { paper-ids: (list) } (map-get? author-papers { author: author }))))
)

;; Update paper status (only contract owner can do this)
(define-public (update-paper-status (paper-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (match (map-get? papers { paper-id: paper-id })
      paper (ok (map-set papers
                  { paper-id: paper-id }
                  (merge paper { status: new-status })))
      (err err-paper-not-found)
    )
  )
)

;; Initialize contract
(begin
  (var-set next-paper-id u0)
)
