;; Impact Network Smart Contract
;; Features: Track academic papers, create citations, measure impact, validate credentials

(define-constant NETWORK_ADMIN tx-sender)
(define-constant ERR_ACCESS_DENIED (err u200))
(define-constant ERR_ALREADY_EXISTS (err u201))
(define-constant ERR_NOT_FOUND (err u202))
(define-constant ERR_INVALID_CITATION (err u203))
(define-constant ERR_INVALID_INPUT (err u204))
(define-constant ERR_MALFORMED_REQUEST (err u205))

;; Data Storage Maps

(define-map academic-papers
  { paper-id: (string-ascii 64) }
  {
    title: (string-ascii 256),
    author: principal,
    submission-time: uint,
    field-of-study: (string-ascii 64),
    abstract: (string-utf8 1024),
    is-peer-reviewed: bool
  }
)

(define-map citation-network
  {
    citing-paper: (string-ascii 64),
    cited-paper: (string-ascii 64)
  }
  {
    citation-time: uint,
    citation-context: (optional (string-utf8 256)),
    relevance-score: uint
  }
)

(define-map impact-metrics
  { paper-id: (string-ascii 64) }
  { citation-count: uint }
)

(define-map scholar-profiles
  { scholar: principal }
  {
    paper-count: uint,
    total-citations: uint,
    impact-score: uint
  }
)

(define-map field-statistics
  { field-name: (string-ascii 64) }
  {
    paper-count: uint,
    citation-count: uint
  }
)

(define-map scholar-rewards
  { scholar: principal }
  { reward-points: uint }
)

(define-map peer-reviewers
  { reviewer: principal }
  { is-authorized: bool }
)

;; Input Validation Functions

(define-private (is-valid-text (input (string-ascii 256)))
  (> (len input) u0)
)

(define-private (is-valid-optional-context (input (optional (string-utf8 256))))
  (match input
    some-value (> (len some-value) u0)
    true
  )
)

(define-private (is-valid-paper-id (paper-id (string-ascii 64)))
  (and (> (len paper-id) u0) (<= (len paper-id) u64))
)

(define-private (is-valid-user (user principal))
  (not (is-eq user 'SPNWZ5V2TPWGQGVDR6T7B6RQ4XMGZ4PXTEE0VQ0S))
)

;; Setup Functions

(define-private (initialize-impact-metrics (paper-id (string-ascii 64)))
  (map-set impact-metrics { paper-id: paper-id } { citation-count: u0 })
)

(define-private (initialize-scholar-profile (scholar principal))
  (let ((existing (map-get? scholar-profiles { scholar: scholar })))
    (if (is-some existing)
      true
      (map-set scholar-profiles
        { scholar: scholar }
        { paper-count: u0, total-citations: u0, impact-score: u100 }
      )
    )
  )
)

(define-private (initialize-field-stats (field (string-ascii 64)))
  (let ((existing (map-get? field-statistics { field-name: field })))
    (if (is-some existing)
      true
      (map-set field-statistics
        { field-name: field }
        { paper-count: u0, citation-count: u0 }
      )
    )
  )
)

(define-private (initialize-scholar-rewards (scholar principal))
  (let ((existing (map-get? scholar-rewards { scholar: scholar })))
    (if (is-some existing)
      true
      (map-set scholar-rewards
        { scholar: scholar }
        { reward-points: u0 }
      )
    )
  )
)

;; Default value getters
(define-private (get-default-scholar-profile)
  { paper-count: u0, total-citations: u0, impact-score: u100 }
)

(define-private (get-default-field-stats)
  { paper-count: u0, citation-count: u0 }
)

(define-private (get-default-rewards)
  { reward-points: u0 }
)

;; Core Public Functions

(define-public (submit-paper
                (paper-id (string-ascii 64))
                (title (string-ascii 256))
                (field (string-ascii 64))
                (abstract (string-utf8 1024)))
  (let ((author tx-sender)
        (existing (map-get? academic-papers { paper-id: paper-id })))
    (begin
      ;; Validate inputs
      (asserts! (is-valid-paper-id paper-id) ERR_MALFORMED_REQUEST)
      (asserts! (is-valid-text title) ERR_MALFORMED_REQUEST)
      (asserts! (is-valid-text field) ERR_MALFORMED_REQUEST)
      (asserts! (> (len abstract) u0) ERR_MALFORMED_REQUEST)
      (asserts! (is-none existing) ERR_ALREADY_EXISTS)
      
      ;; Setup author profile
      (initialize-scholar-profile author)
      (let ((current-profile (default-to (get-default-scholar-profile)
                                        (map-get? scholar-profiles 
                                                 { scholar: author }))))
        (map-set scholar-profiles
          { scholar: author }
          (merge current-profile 
                { paper-count: (+ (get paper-count current-profile) u1) })
        )
      )
      
      ;; Setup field statistics
      (initialize-field-stats field)
      (let ((current-stats (default-to (get-default-field-stats)
                                      (map-get? field-statistics 
                                               { field-name: field }))))
        (map-set field-statistics
          { field-name: field }
          (merge current-stats 
                { paper-count: (+ (get paper-count current-stats) u1) })
        )
      )
      
      ;; Create paper entry
      (map-set academic-papers
        { paper-id: paper-id }
        {
          title: title,
          author: author,
          submission-time: block-height,
          field-of-study: field,
          abstract: abstract,
          is-peer-reviewed: false
        }
      )
      
      ;; Initialize metrics and rewards
      (initialize-impact-metrics paper-id)
      (initialize-scholar-rewards author)
      
      (ok true)
    )
  )
)

(define-public (add-citation
               (citing-paper (string-ascii 64))
               (cited-paper (string-ascii 64))
               (context (optional (string-utf8 256)))
               (relevance uint))
  (let ((citing-data (map-get? academic-papers { paper-id: citing-paper }))
        (cited-data (map-get? academic-papers { paper-id: cited-paper })))
    (begin
      ;; Validate inputs
      (asserts! (is-valid-paper-id citing-paper) ERR_MALFORMED_REQUEST)
      (asserts! (is-valid-paper-id cited-paper) ERR_MALFORMED_REQUEST)
      (asserts! (is-valid-optional-context context) ERR_MALFORMED_REQUEST)
      (asserts! (is-some citing-data) ERR_NOT_FOUND)
      (asserts! (is-some cited-data) ERR_NOT_FOUND)
      
      ;; Check authorization
      (asserts! (is-eq tx-sender 
                      (get author (unwrap! citing-data ERR_NOT_FOUND))) 
                ERR_ACCESS_DENIED)
      
      ;; Prevent self-citation
      (asserts! (not (is-eq citing-paper cited-paper)) ERR_INVALID_CITATION)
      
      ;; Validate relevance score
      (asserts! (and (>= relevance u1) (<= relevance u10)) ERR_INVALID_INPUT)
      
      ;; Record citation
      (map-set citation-network
        { citing-paper: citing-paper, cited-paper: cited-paper }
        {
          citation-time: block-height,
          citation-context: context,
          relevance-score: relevance
        }
      )
      
      ;; Update citation count
      (let ((current-count (get citation-count 
                               (default-to { citation-count: u0 }
                                          (map-get? impact-metrics 
                                                   { paper-id: cited-paper })))))
        (map-set impact-metrics
          { paper-id: cited-paper }
          { citation-count: (+ current-count u1) }
        )
      )
      
      ;; Update cited author profile
      (let ((cited-author (get author (unwrap! cited-data ERR_NOT_FOUND)))
            (current-profile (default-to (get-default-scholar-profile)
                                        (map-get? scholar-profiles 
                                                 { scholar: (get author 
                                                           (unwrap! cited-data 
                                                                  ERR_NOT_FOUND)) }))))
        (map-set scholar-profiles
          { scholar: cited-author }
          (merge current-profile 
                { 
                  total-citations: (+ (get total-citations current-profile) u1),
                  impact-score: (+ (get impact-score current-profile) relevance)
                })
        )
      )
      
      ;; Update field statistics
      (let ((cited-field (get field-of-study (unwrap! cited-data ERR_NOT_FOUND)))
            (current-stats (default-to (get-default-field-stats)
                                      (map-get? field-statistics 
                                               { field-name: (get field-of-study 
                                                             (unwrap! cited-data 
                                                                    ERR_NOT_FOUND)) }))))
        (map-set field-statistics
          { field-name: cited-field }
          (merge current-stats 
                { citation-count: (+ (get citation-count current-stats) u1) })
        )
      )
      
      ;; Add reward points
      (let ((cited-author (get author (unwrap! cited-data ERR_NOT_FOUND)))
            (current-rewards (default-to (get-default-rewards)
                                        (map-get? scholar-rewards 
                                                 { scholar: (get author 
                                                           (unwrap! cited-data 
                                                                  ERR_NOT_FOUND)) }))))
        (map-set scholar-rewards
          { scholar: cited-author }
          { reward-points: (+ (get reward-points current-rewards) relevance) }
        )
      )
      
      (ok true)
    )
  )
)

(define-public (peer-review-paper (paper-id (string-ascii 64)))
  (let ((paper-data (map-get? academic-papers { paper-id: paper-id }))
        (reviewer-status (map-get? peer-reviewers { reviewer: tx-sender })))
    (begin
      (asserts! (is-valid-paper-id paper-id) ERR_MALFORMED_REQUEST)
      (asserts! (is-some paper-data) ERR_NOT_FOUND)
      (asserts! (is-some reviewer-status) ERR_ACCESS_DENIED)
      (asserts! (get is-authorized (unwrap! reviewer-status ERR_ACCESS_DENIED)) 
                ERR_ACCESS_DENIED)
      
      ;; Update paper status
      (map-set academic-papers
        { paper-id: paper-id }
        (merge (unwrap! paper-data ERR_NOT_FOUND) { is-peer-reviewed: true })
      )
      
      ;; Bonus score for peer review
      (let ((author (get author (unwrap! paper-data ERR_NOT_FOUND)))
            (current-profile (default-to (get-default-scholar-profile)
                                        (map-get? scholar-profiles 
                                                 { scholar: (get author 
                                                           (unwrap! paper-data 
                                                                  ERR_NOT_FOUND)) }))))
        (map-set scholar-profiles
          { scholar: author }
          (merge current-profile 
                { impact-score: (+ (get impact-score current-profile) u50) })
        )
      )
      
      (ok true)
    )
  )
)

(define-public (authorize-peer-reviewer (reviewer principal))
  (begin
    (asserts! (is-valid-user reviewer) ERR_MALFORMED_REQUEST)
    (asserts! (not (is-eq reviewer tx-sender)) ERR_MALFORMED_REQUEST)
    (asserts! (is-eq tx-sender NETWORK_ADMIN) ERR_ACCESS_DENIED)
    
    (let ((existing (map-get? peer-reviewers { reviewer: reviewer })))
      (asserts! (or (is-none existing) 
                    (not (get is-authorized (default-to { is-authorized: false } existing)))) 
                ERR_ALREADY_EXISTS)
    )
    
    (map-set peer-reviewers { reviewer: reviewer } { is-authorized: true })
    (ok true)
  )
)

(define-public (revoke-peer-reviewer (reviewer principal))
  (begin
    (asserts! (is-valid-user reviewer) ERR_MALFORMED_REQUEST)
    (asserts! (is-eq tx-sender NETWORK_ADMIN) ERR_ACCESS_DENIED)
    
    (let ((existing (map-get? peer-reviewers { reviewer: reviewer })))
      (asserts! (is-some existing) ERR_NOT_FOUND)
      (asserts! (get is-authorized (default-to { is-authorized: false } existing)) 
                ERR_NOT_FOUND)
    )
    
    (map-set peer-reviewers { reviewer: reviewer } { is-authorized: false })
    (ok true)
  )
)

(define-public (claim-reward-points)
  (let ((scholar tx-sender)
        (current-rewards (default-to (get-default-rewards)
                                    (map-get? scholar-rewards 
                                             { scholar: scholar }))))
    (begin
      (asserts! (> (get reward-points current-rewards) u0) ERR_INVALID_INPUT)
      
      (map-set scholar-rewards
        { scholar: scholar }
        { reward-points: u0 }
      )
      
      (ok (get reward-points current-rewards))
    )
  )
)

;; Read-only Query Functions

(define-read-only (get-paper-info (paper-id (string-ascii 64)))
  (map-get? academic-papers { paper-id: paper-id })
)

(define-read-only (get-citation-info (citing-paper (string-ascii 64)) 
                                    (cited-paper (string-ascii 64)))
  (map-get? citation-network 
           { citing-paper: citing-paper, cited-paper: cited-paper })
)

(define-read-only (get-paper-citations (paper-id (string-ascii 64)))
  (default-to { citation-count: u0 } 
             (map-get? impact-metrics { paper-id: paper-id }))
)

(define-read-only (get-scholar-profile (scholar principal))
  (default-to { paper-count: u0, total-citations: u0, impact-score: u0 }
             (map-get? scholar-profiles { scholar: scholar }))
)

(define-read-only (get-field-stats (field (string-ascii 64)))
  (default-to { paper-count: u0, citation-count: u0 }
             (map-get? field-statistics { field-name: field }))
)

(define-read-only (get-scholar-rewards (scholar principal))
  (get reward-points (default-to (get-default-rewards)
                                (map-get? scholar-rewards 
                                         { scholar: scholar })))
)

(define-read-only (calculate-h-index (scholar principal))
  (let ((profile (map-get? scholar-profiles { scholar: scholar })))
    (if (is-some profile)
      (let ((citations (get total-citations (unwrap! profile (err u0))))
            (papers (get paper-count (unwrap! profile (err u0)))))
        (if (and (> citations u0) (> papers u0))
          (ok (if (> citations u100) u10
                (if (> citations u81) u9
                  (if (> citations u64) u8
                    (if (> citations u49) u7
                      (if (> citations u36) u6
                        (if (> citations u25) u5
                          (if (> citations u16) u4
                            (if (> citations u9) u3
                              (if (> citations u4) u2 u1)
                            )
                          )
                        )
                      )
                    )
                  )
                )
              ))
          (ok u0)
        )
      )
      (err u0)
    )
  )
)

(define-read-only (is-authorized-reviewer (reviewer principal))
  (let ((status (map-get? peer-reviewers { reviewer: reviewer })))
    (if (is-some status)
      (get is-authorized (unwrap! status false))
      false
    )
  )
)

(define-read-only (get-paper-citations-by-direction (paper-id (string-ascii 64)) 
                                                   (as-cited bool))
  (if as-cited
    (ok "Papers citing this work would be returned with pagination")
    (ok "Papers cited by this work would be returned with pagination")
  )
)