#lang racket/base
(require pict
         unstable/gui/ppict
         racket/format
         puresuri)

(define GRID? #f)
(puresuri-add-char-handler! #\g (λ () (set! GRID? (not GRID?))))

(define grid-background
  (let ([w slide-w]
        [h slide-h])
    (let loop ([hl (colorize (hline w 1) "gray")]
               [vl (colorize (vline 1 h) "gray")]
               [pict (blank w h)]
               [pos 0])
      (cond [(>= pos 1.05) pict]
            [else
             (loop hl vl
                   (ppict-do
                    pict
                    #:go (coord 0 pos 'lc)
                    hl
                    #:go (coord 0 pos 'lt)
                    (colorize (text (~r pos #:precision 2)) "gray")
                    #:go (coord pos 0 'lt)
                    (colorize (text (~r pos #:precision 2)) "gray")
                    #:go (coord pos 0 'ct)
                    vl)
                   (+ pos 0.05))]))))
(puresuri-pipeline-snoc!
 (λ (p)
   (if GRID?
     (cc-superimpose
      p
      grid-background)
     p)))
