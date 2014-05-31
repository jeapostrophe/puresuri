#lang racket/base
(require racket/class
         racket/list
         racket/contract/base
         racket/gui/base
         racket/match
         pict
         unstable/gui/ppict
         racket/rerequire
         data/queue
         "puresuri.rkt"
         "puresuri-internal.rkt")

;; xxx move to pict library
(define (draw-pict-centered p dc aw ah)
  (define pw (pict-width p))
  (define ph (pict-height p))
  (define (inset x y)
    (/ (- x y) 2))
  (draw-pict p dc (inset aw pw) (inset ah ph)))

(define (puresuri! mp)
  (define the-ST (make-fresh-ST))

  (define pres-frame%
    (class frame%
      (define/override (on-size w h)
        (refresh!))
      (define/override (on-subwindow-char w e)
        (define k (send e get-key-code))
        (define h (hash-ref (ST-handlers the-ST) k #f))
        (cond
          [h
           (h)
           (refresh!)]
          [else
           (match k
             [(or #\q 'escape)
              (exit 0)]
             ;; xxx slide names
             [(or #\space 'right)
              (set! current-slide (add1 current-slide))
              (refresh!)]
             [(or 'left)
              (set! current-slide (max 0 (sub1 current-slide)))
              (refresh!)]
             [_
              #f])]))
      (super-new)))

  (define current-slide 0)
  (define (paint-canvas c dc)
    (send dc set-background "black")
    (send dc clear)

    (define-values (aw ah)
      (send c get-client-size))
    (define base (blank slide-w slide-h))
    (define almost-pict
      (cmds->pict current-slide base (ST-cmds the-ST)))
    (define nearly-pict
      (apply-pipeline (ST-pipeline the-ST) almost-pict))
    (define final-pict
      (scale-to-fit (clip nearly-pict) aw ah))
    (draw-pict-centered final-pict the-dc aw ah))

  (define pf (new pres-frame% [label "Puresuri"]))
  (define pc (new canvas% [parent pf]
                  [paint-callback paint-canvas]))
  (define (refresh!)
    (send pc refresh))
  (define the-dc (send pc get-dc))
  (dc-for-text-size the-dc)

  (define (error-display x)
    ((error-display-handler)
     (if (exn? x)
       (exn-message x)
       "non-exn error:")
     x))

  (define (load-mp!)
    (define new-ST (make-fresh-ST))
    (with-handlers ([(λ (x)
                       (not (exn:break? x)))
                     (λ (x)
                       ;; xxx put error message on screen
                       (error-display x))])
      (parameterize ([current-ST new-ST])
        (dynamic-rerequire mp #:verbosity 'reload))
      (set! the-ST new-ST))
    (refresh!))

  (load-mp!)

  (send pf show #t)

  (let loop ()
    (yield (filesystem-change-evt mp))
    (load-mp!)
    (loop)))

(module+ main
  (require racket/cmdline)

  (current-command-line-arguments
   (vector "example.rkt"))

  ;; xxx printing

  (command-line
   #:program "puresuri"
   #:args (module-path)
   (puresuri! module-path)))
