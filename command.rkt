#lang racket/base
(require racket/class
         racket/list
         racket/contract/base
         racket/gui/base
         racket/match
         pict
         unstable/error
         puresuri
         puresuri/pict
         "private/param.rkt"
         "private/state.rkt"
         racket/runtime-path
         lux
         lux/chaos/gui
         lux/chaos/gui/val
         lux/chaos/gui/key)

(define (load-mp w)
  (define mp (pres-mp w))
  (define cur (file-or-directory-modify-seconds mp))
  (cond
   [(< (pres-load-time w) cur)
    (with-handlers ([exn:not-break?
                     (λ (x)
                       (error-display x)
                       w)])
      (refresh
       (struct-copy pres w
                    [load-time cur]
                    [fe
                     (let ()
                       (define fce (filesystem-change-evt mp))
                       (define done? #t)
                       (define the-evt
                         (wrap-evt fce
                                 (λ (_)
                                   (set! done? #t)
                                   'file-changed)))
                       (guard-evt (λ () (if done? never-evt the-evt))))]
                    [the-ST (load-slides mp)])
       #f))]
   [else
    w]))

(define (refresh w run-effect?)
  (define-values (actual-slide nearly-pict animated?)
    (ST->slide-pict (pres-the-ST w) (pres-slide-n w) run-effect?))
  (struct-copy pres w
               [last-pict nearly-pict]
               [animated? animated?]))

(struct pres
  (mp g/v load-time the-ST slide-n animated? last-pict fe)
  #:methods gen:word
  [(define (word-fps w)
     (if (pres-animated? w)
         15.0
         0.0))
   (define (word-label s ft)
     (lux-standard-label "Puresuri" ft))
   (define (word-event w e)
     (define new-w
       (cond
        [(eq? e 'closed)
         #f]
        [(key-event? e)
         (define k (send e get-key-code))
         (define h (ST-char-handler (pres-the-ST w) k))
         (cond
          [h
           (h)
           (refresh w #f)]
          [else
           (match k
             [(or #\q 'escape)
              #f]
             [(or #\space 'right)
              (refresh
               (struct-copy
                pres w
                [slide-n (add1 (pres-slide-n w))])
               #t)]
             [(or 'left)
              (refresh
               (struct-copy
                pres w
                [slide-n (max 0 (sub1 (pres-slide-n w)))])
               #f)]
             [#\i
              (refresh
               (struct-copy
                pres w
                [slide-n
                 (if (= (pres-slide-n w) +inf.0)
                     0
                     +inf.0)])
               #f)]
             [else
              w])])]
        [else
         w]))
     (and new-w
          (load-mp new-w)))
   (define (word-evt w)
     (pres-fe w))
   (define (word-tick w)
     (refresh w #f))
   (define (word-output w)
     (define lp (pres-last-pict w))
     ((pres-g/v w) lp))])

(define (make-pres mp)
  (load-mp (pres mp (make-gui/val) -inf.0 (make-fresh-ST) 0 #f #f never-evt)))

(define-runtime-path slides.png "slides.png")
(define (puresuri mp)
  (call-with-chaos
   (make-gui #:icon slides.png #:width slide-w #:height slide-h)
   (λ ()    
     (fiat-lux (make-pres mp)))))

(define (load-slides mp)
  (define new-ST (make-fresh-ST))
  (define ns (make-base-namespace))
  (namespace-attach-module (current-namespace) 'racket/gui/base ns)
  (namespace-attach-module (current-namespace) 'puresuri/main ns)
  (parameterize ([current-ST new-ST]
                 [current-namespace ns])
    (namespace-require `(file ,mp)))
  new-ST)

(define (ST->slide-pict st i run-effect?)
  (define base
    (colorize (filled-rectangle slide-w slide-h) "white"))
  (define-values (actual-slide almost-pict slide-animated?)
    (ST-cmds-interp st i run-effect? base))
  (define-values (post-pipe-pict pipe-animated?)
    (parameterize ([current-slide-number actual-slide])
      (ST-pipeline-apply st almost-pict)))  
  (define animated?
    (or slide-animated?
        pipe-animated?))
  (define nearly-pict
    (clip post-pipe-pict))
  (values actual-slide nearly-pict animated?))

(define (ST->picts st)
  (let loop ([i 0])
    (define-values (ni p a?) (ST->slide-pict st i #f))
    (cons p (if (= i ni) empty (loop ni)))))

(define (puresuri->png-dir png-dir mp)
  (local-require racket/file
                 racket/format)
  (printf "Creating directory ~a\n" png-dir)
  (make-directory* png-dir)
  (printf "Loading slides...\n")
  (define the-ST (load-slides mp))
  (printf "Rendering slides...\n")
  (define ps (ST->picts the-ST))
  (define how-many (length ps))
  (define len (string-length (number->string how-many)))
  (for ([p (in-list ps)]
        [i (in-naturals)])
    (define ni
      (~a i #:min-width len #:align 'right #:pad-string "0"))
    (printf "Saving slide ~a...\n" ni)
    (define bm (pict->bitmap p))
    (send bm save-file
          (build-path png-dir (format "~a.png" ni))
          'png
          100)))

(define (puresuri->pdf pdf-p mp)
  (local-require racket/file
                 racket/system)
  (define png-dir (make-temporary-file "~a-pngs" 'directory))
  (puresuri->png-dir png-dir mp)
  (define pngs (sort (map path->string (directory-list png-dir)) string-ci<=?))
  (define pdf.tex (build-path png-dir "pdf.tex"))
  (with-output-to-file pdf.tex
    (λ ()
      (displayln "\\documentclass{article}")
      (displayln "\\usepackage[active,tightpage]{preview}")
      (displayln "\\usepackage{graphicx}")
      (displayln "\\begin{document}")
      (for ([p (in-list pngs)])
        (displayln
         (format "\\begin{preview}\\includegraphics{~a}\\end{preview}" p)))
      (displayln "\\end{document}")))
  (dynamic-wind
    void
    (λ ()
      (parameterize ([current-directory png-dir])
        (system (format "pdflatex ~a" pdf.tex)))
      (copy-file (build-path png-dir "pdf.pdf") pdf-p #t))
    (λ ()
      (delete-directory/files png-dir))))

(module+ main
  (require racket/cmdline
           raco/command-name)

  (define operation puresuri)

  (command-line
   #:program (short-program+command-name)
   #:once-any
   [("--pngs") png-dir "Render as directory of pngs"
    (set! operation
          (λ (mp)
            (puresuri->png-dir png-dir mp)))]
   [("--pdf") pdf-p "Render as a PDF"
    (set! operation
          (λ (mp)
            (puresuri->pdf pdf-p mp)))]
   #:args (module-path)
   (cond
    [(file-exists? module-path)
     (operation module-path)]
    [else
     (error 'puresuri "File does not exist: ~e" module-path)])))
