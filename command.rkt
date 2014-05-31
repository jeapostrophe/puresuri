#lang racket/base
(require racket/class
         racket/list
         racket/contract/base
         racket/gui/base
         racket/match
         pict
         racket/rerequire
         puresuri
         puresuri/pict
         "private/param.rkt"
         "private/state.rkt")

;; xxx put in a library
(define (error-display x)
  ((error-display-handler)
   (if (exn? x)
     (exn-message x)
     "non-exn error:")
   x))

(define (puresuri! mp)
  (define the-ST (make-fresh-ST))

  (define pres-frame%
    (class frame%
      (define/override (on-size w h)
        (refresh!))
      (define/override (on-subwindow-char w e)
        (define k (send e get-key-code))
        (define h (ST-char-handler the-ST k))
        (cond
          [h
           (h)
           (refresh!)]
          [else
           (match k
             [(or #\q 'escape)
              (exit 0)]
             [(or #\space 'right)
              (set! current-slide (add1 current-slide))
              (refresh!)]
             [(or 'left)
              (set! current-slide (max 0 (sub1 current-slide)))
              (refresh!)]
             [#\r
              (refresh!)]
             [#\i
              (set! current-slide
                    (if (= current-slide +inf.0)
                      0
                      +inf.0))
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
    (define base
      (colorize (filled-rectangle slide-w slide-h) "white"))
    (define-values (actual-slide almost-pict)
      (ST-cmds-interp the-ST current-slide base))
    (define nearly-pict
      (parameterize ([current-slide-number actual-slide])
        (ST-pipeline-apply the-ST almost-pict)))
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

  (define (load-mp!)
    (define new-ST (make-fresh-ST))
    (with-handlers ([(λ (x)
                       (not (exn:break? x)))
                     error-display])
      (parameterize ([current-ST new-ST])
        (dynamic-rerequire `(file ,mp) #:verbosity 'reload))
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

  ;; xxx printing

  (command-line
   #:program "puresuri"
   #:args (module-path)
   (puresuri! module-path)))
