#lang scribble/manual
@require[scribble/bnf
         @for-label[puresuri
                    puresuri/lib/cmds
                    puresuri/lib/title
                    puresuri/lib/grid
                    puresuri/lib/slide-numbers
                    ppict/align
                    pict
                    racket/contract/base
                    racket/gui/base
                    racket/base]]

@title{puresuri: the king of presentations}
@author{Jay McCarthy}

@defmodule[puresuri]

Puresuri (pronounced: プレスリ) is a re-imagining of
@racketmodname[slideshow] as an imperative canvas that is
incrementally drawn on and explored during presentations.

@local-table-of-contents[]

@section{Displaying Puresuri Presentations}

The @exec{raco puresuri} command accepts the path of a file that
contains a module that runs Puresuri @tech{commands}.

@itemize[

@item{@DFlag{pngs} @nonterm{png-dir} --- Renders the slideshow
statically into a directory of PNG files specified by
@nonterm{png-dir}.}

@item{@DFlag{pdf} @nonterm{pdf-p} --- Renders the slideshow statically
as PDF file specified by @nonterm{pdf-p} path.}

]

This command will monitor the path of the file and if it changes,
reload the slide and resume from the current slide.

A Puresuri slideshow is created by running a sequence of
@tech{commands}. Commands add (@racket[add!]) and
remove (@racket[remove!]) picts to the canvas. Commands also mark
intermediate points in the command stream as a
slide (@racket[commit!]) such that the Puresuri user interface
requires a button press to continue on to the next slide.

Puresuri tracks picts added to the canvas with @deftech{tag}s, which
are symbols. If @racket[remove!] is called with a tag that is on the
canvas, then that pict will be removed.

Puresuri can save the state of the canvas with the @racket[save!]
command into a @deftech{save object} and then restore it later with
the @racket[restore!] command. This is useful for creating a template
slide and reusing it throughout the presentation without having to
create a function for creating that template.

Puresuri supports @deftech{animation} through picts wrapped in
thunks. If the canvas contains any of these @racket[lazy-pict/c]
structures, then Puresuri will update the display reguarly.

Whenever Puresuri is about to display the current canvas, it calls the
current @deftech{pipeline} with the canvas pict. The functions in the
pipeline (which can be adjusted with @racket[puresuri-pipeline-snoc!])
can modify the pict in arbitrary ways before it is displayed. This is
how @racketmodname[puresuri/lib/slide-numbers] adds a slide number to
the bottom-right corner.

The Puresuri user interface supports the following key bindings:

@itemlist[

@item{@litchar{q}, @litchar{ESC} --- Quit the presentation.}

@item{@litchar{SPACE}, @litchar{RIGHT} --- Advance to the next slide.}

@item{@litchar{LEFT} --- Revert to the previous slide.}

@item{@litchar{i} --- Go to the beginning or end of the presentation.}

]

Puresuri presentations can extend this set of key bindings by creating
a @deftech{handler} with @racket[puresuri-add-char-handler!].

@section{Core API}

This section documents Puresuri @deftech{commands}.

@defthing[slide-w exact-nonnegative-integer?]{

The width of a slide.}

@defthing[slide-h exact-nonnegative-integer?]{

The height of a slide.}

@defthing[placer/c contract?]{

A contract for @tech{placer}s. Equivalent to @racket[(-> pict?
pict? (values placer/c pict?))]. A @deftech{placer}'s job is to put
one pict (the second one) on top of another pict (the first) in a
particular place and then return a new @tech{placer} and the super-imposed
pict.}

@defproc[(exact-placer [dx real?] [dy real?] [a align/c]) placer/c]{

Returns a @tech{placer} that puts the pict aligned according to
@racket[a] at the spot (@racket[dx],@racket[dy]).}

@defproc[(relative-placer [rx real?] [ry real?] [a align/c]) placer/c]{

Returns a @tech{placer} that puts the pict aligned according to
@racket[a] at the spot (@racket[(* rx slide-w)],@racket[(* ry
slide-h)]).}

@defproc[(at-placer [t (or/c tag-path? pict-path?)] 
                    [finder 
                     (-> pict? pict-path? (values real? real?))
                     cc-find]
                    [a align/c 'cc])
         placer/c]{

Returns a @tech{placer} that puts the pict aligned according to
@racket[a] at the spot returned by @racket[finder] called on the base
pict and @racket[t].}

@defproc[(go! [pl placer/c]) void?]{

Changes the active @tech{placer} to @racket[pl].}

@defthing[lazy-pict/c contract?]{

A contract for lazy picts. Equivalent to @racket[(or/c pict? (->
pict?))].}

@defproc[(add! [p lazy-pict/c] [#:tag tag (or/c #f symbol?) #f]) void?]{

Adds the pict @racket[p] to the canvas at the location of the current
@tech{placer} with the @tech{tag} @racket[tag]. If @racket[p] is a
thunk, then the current slide has @tech{animation}.}

@defproc[(remove! [tag symbol?]) void?]{

Removes the pict with the tag @racket[tag] from the canvas.}

@defproc[(commit! [#:effect effect (-> any) void]) void?]{

Begins a new slide that runs @racket[effect] when it is transistioned
to from the left.}

@defproc[(clear!) void?]{

Clears the canvas.}

@defproc[(plpict? [x any/c]) boolean?]{
 
Identifiers picts with embedded @tech{placers}.}

@defproc[(transform! [t (-> plpict? (values plpict? boolean?))]) void?]{

Calls @racket[t] with the current canvas and replaces the canvas with
what @racket[t] returns. If @racket[t] is animated, then the boolean
return should be @racket[#t].}

@defproc[(save? [x any/c]) boolean?]{

Identifies @tech{save objects}.}

@defproc[(save!) save?]{

Returns the current canvas as a @tech{save object}.}

@defproc[(restore! [s save?]) void?]{

Replaces the current canvas with the @tech{save object} @racket[s].}

@defthing[pipeline/c contract?]{

A contract for @tech{pipeline}s. Equivalent to @racket[(->
pict? (values pict? boolean?))]. If the pipeline is animated, then the
boolean return should be @racket[#t].}

@defproc[(puresuri-pipeline-snoc! [p pipeline/c]) void?]{

Adds @racket[p] to the pipeline.}

@defthing[current-slide-number (parameter/c exact-nonnegative-integer?)]{

The current slide number. This is only set during the evaluation of
the @tech{pipeline}.}

@defthing[charcode/c contract?]{

A contract for @deftech{char code}s. Equivalent to @racket[(or/c char?
key-code-symbol?)].}

@defproc[(puresuri-add-char-handler! [cc charcode/c] [h (-> any)]) void?]{
 
Adds @racket[h] as the @tech{handler} for @racket[cc].}

@section{Libraries}

The core of Puresuri is designed to be tight and flexible so that
other features may be added as libraries. Please submit pull requests
with useful additions!

@subsection{Helper Commands}
@defmodule[puresuri/lib/cmds]

@defproc[(bind! [t (-> pict? pict?)]) void?]{

Calls @racket[t] with the current canvas and expects it return a new
canvas. Does not modify the active @tech{placer}.}

@defproc[(replace! [t symbol?] [p lazy-pict/c]) void?]{

Removes the pict with the tag @racket[t] and adds @racket[p] over its
center.}

@defproc[(slide! [#:effect effect (-> any) void]) void?]{

Calls @racket[commit!] and @racket[clear!] in sequence.}

@subsection{PLT Title Background}
@defmodule[puresuri/lib/title]

@defthing[plt-title-background pict?]{
 
The PLT logo background.}

@subsection{Placement Grid}
@defmodule[puresuri/lib/grid]

Adds a @tech{pipeline} and @tech{handler} that cooperate so that when
@litchar{g} is pressed, a grid appears on the slide to help slide
authors place picts.

@subsection{Slide Numbers}
@defmodule[puresuri/lib/slide-numbers]

Adds a @tech{pipeline} that shows the slide number in the bottom
right-hand corner of the slide.
