#lang racket/base
(require pict
         ppict-slide-grid
         puresuri
         puresuri/plpict
         puresuri/lib/title)
(module+ test)

(define GRID? #f)
(puresuri-add-char-handler! #\g (λ () (set! GRID? (not GRID?))))

(define grid-background (grid-base-pict slide-w slide-h))
(puresuri-pipeline-snoc!
 (λ (p)
   (if GRID?
     (cc-superimpose
      p
      grid-background)
     p)))

(define my-bg (make-plt-title-background* slide-w slide-h))

(go! (relative-placer 1/2 1/2))
(add! my-bg)

(add! (text "On Amazing Slideshows"))

(commit!)

;; xxx add #:label label-e pict-e
;; xxx add #:del label-e
;; xxx typo in ppict-do* do
;; xxx add #:save and #:restore
;; xxx seek to end mode on reload
