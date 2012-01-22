#lang scribble/manual
@(require (for-label (planet dyoo/whalesong/lang/whalesong)))


@title{Writing an RPN Calculator in Whalesong}
@author+email["Danny Yoo" "dyoo@hashcollision.org"]

Let's try to make a simple
@link["http://en.wikipedia.org/wiki/Reverse_Polish_notation"]{Reverse
Polish Notation} (RPN) calculator.  It's one of those toy
examples that are, at the very least, slightly more interesting
than
@link["http://en.wikipedia.org/wiki/Factorial"]{@tt{factorial}},
so let's see what it looks like in Whalesong.



@section{The Model}
First, let's talk about a model of an RPN calculator.  There's a
notion of what digits are showing on the screen of the
calculator, as well as some notion of the calculator's stack.
Let's try coding that up.

@filebox["calc.rkt"]{
@codeblock|{
#lang planet dyoo/whalesong
;; calc is a model of the calculator .
(define-struct calc (stack ;; (listof number)
                     onscreen ;; (listof number)
                     ))

(define THE-EMPTY-CALCULATOR
  (make-calc '() '(0)))

;; insert-digit: calc number -> calc
;; Enters a digit on the calculator
(define (insert-digit calc digit)
  (make-calc (calc-stack calc)
             (cond
              [(equal? (calc-onscreen calc) '(0))
               (list digit)]
              [else
               (append (calc-onscreen calc) (list digit))])))
}|
}


Wait!  We should write test cases, of course!  Let's make sure we
can start inserting digits into this calculator.  Let's add some
tests to the end of @filepath{calc.rkt}.

@racketblock[
(check-expect (insert-digit THE-EMPTY-CALCULATOR 1)
              (make-calc '() '(1)))

(check-expect (insert-digit THE-EMPTY-CALCULATOR 0)
              (make-calc '() '(0)))

(check-expect (insert-digit (insert-digit THE-EMPTY-CALCULATOR 1)
                            2)
              (make-calc '() '(1 2)))
]

If we run this, we should see that our test cases are running fine
so far.

But... hmmm... It's a little awkward to keep nesting calls to
@racket[insert-digit] for our test cases.  Let's write a
quick-and-dirty harness to make it easier to press multiple
@emph{commands} into our calculator.  Let's call it
@racket[press]:

@codeblock|{
;; For the moment, a command is simply a number.

;; press: calc (listof command) -> calc
;; Convenience function doing multiple commands into the calculator at once.
(define (press calc commands)
  (foldl (lambda (digit calc)
           (insert-digit calc digit))
         calc
         commands))
}|

Once we have @racket[press], we can use it for a few more tests:
@codeblock|{
;; If we press zero multiple times before starting to add numbers in,
;; nothing should show up on the display...
(check-expect (press THE-EMPTY-CALCULATOR
                             '(0 0 3 1 4 1 5 9 2 6))
              (make-calc '()
                         '(3 1 4 1 5 9 2 6)))

;; but of course, zero should be significant once we start
;; entering numbers.
(check-expect (press THE-EMPTY-CALCULATOR
                             '(0 0 3 0 0))
              (make-calc '()
                         '(3 0 0)))
}|


Ok, this looks good so far.  Let's add functionality to
@emph{enter} a number into the stack.  Effectively, this will put
the number in the @racket[calc-onscreen] into the stack.  First, we'll probably
need a function to take a list of digits and turn that into
a number.  Let's call this @racket[digits->number].
@codeblock|{
;; digits->number: (listof number) -> number
;; Take the digits and condense them into a single number.
(define (digits->number digits)
  (foldl (lambda (digit acc)
           (+ (* acc 10) digit))
         0
         digits))

(check-expect (digits->number '(0))
              0)

(check-expect (digits->number '(4 2))
             42)

(check-expect (digits->number '(1 2 3 4))
              1234)
}|


Next, now that we've got @racket[digits->number], let's use it.
Here's an implementation of @racket[push-stack], which takes the
number onscreen and places it onto the stack.
@codeblock|{
;; push-stack: calc -> calc
;; Put the number in the onscreen window onto the stack,
;; and reset the onscreen back to '(0).
(define (push-stack calc)
  (make-calc (cons (digits->number (calc-onscreen calc))
                   (calc-stack calc))
             '(0)))

(check-expect (push-stack THE-EMPTY-CALCULATOR)
              (make-calc '(0)
                         '(0)))

(check-expect (push-stack (push-stack THE-EMPTY-CALCULATOR))
              (make-calc '(0 0)
                         '(0)))

(check-expect (push-stack
               (press
                (push-stack
                 (press THE-EMPTY-CALCULATOR '(3 1 4)))
                '(4 5 6)))
              (make-calc '(456 314)
                         '(0)))
}|

The last test is somewhat ugly to read: we end up having to read
how it works inside-out.  We tried to make it easy to write tests
with multiple uses of @racket[insert-digit] by defining a
@racket[press] function: maybe we can expand on the idea of a
@emph{command} so it includes, not only numeric digits, but
things like @racket['enter].  We'll revise our definition of
@racket[press] to work on both digits and the @racket['enter]
command.

@codeblock|{
;; A command is a number, or the symbol 'enter.

;; press: calc (listof command) -> calc
;; Convenience function doing multiple commands into the calculator at once.
(define (press calc commands)
  (foldl (lambda (cmd calc)
           (cond
            [(number? cmd)
             (insert-digit calc cmd)]
            [(eq? cmd 'enter)
             (push-stack calc)]
            [else
             (error 'press "Unknown command: ~e" cmd)]))
         calc
         commands))
}|