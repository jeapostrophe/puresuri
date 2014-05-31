#lang racket/base
(require pict
         ppict-slide-grid
         puresuri
         puresuri/plpict
         unstable/gui/pict
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

(go! (relative-placer 1/2 1/2 'cc))
(add! my-bg)
(go! (relative-placer 1/2 1/2 'cc))
(add! (text "On Amazing Slideshows" null 60))
(add! (text "Jay McCarthy" null 30))
(add! (text "Vassar & PLT" null 20))
(commit!)
(clear!)

(add! (text "What time is it?" null 60))
(commit!)
(add! (λ () (text (number->string (current-seconds)) null 60)))
(commit!)
(clear!)

(go! (relative-placer 0 0 'lt))
(add! #:tag 'circA (circle 20))
(go! (relative-placer 1 1 'rb))
(add! #:tag 'circB (circle 20))
(bind!
 (λ (p)
   (pin-arrow-line 10 p
                   (find-tag p 'circA) rb-find
                   (find-tag p 'circB) lt-find)))


;; xxx add #:del label-e
;; xxx add #:save and #:restore
;; xxx seek to end mode on reload
