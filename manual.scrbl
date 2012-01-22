#lang scribble/manual


@title{Writing an RPN Calculator}
@author+email["Danny Yoo" "dyoo@hashcollision.org"]

Let's try to make a simple
@link["http://en.wikipedia.org/wiki/Reverse_Polish_notation"]{Reverse
Polish Notation} (RPN) calculator.  It's one of those toy
examples that is, at the very least, slightly more interesting
than
@link["http://en.wikipedia.org/wiki/Factorial"]{@tt{factorial}},
so let's see what it looks like in Racket/Whalesong.


@;; Should we mention http://programmingpraxis.com/2009/02/19/rpn-calculator/ at all?


@section{The Model}

When we start pressing numbers on the calculator, it changes the
displayed number on-screen by inserting digits at the end.
There's also some hidden state in the form of the numeric stack.
Let's first use a structure to hold two pieces of a calculator's
state.  Create a new file called @filepath{calc.rkt}, and start
editing it.

@filebox["calc.rkt"]{
@codeblock|{
#lang planet dyoo/whalesong
;; calc is a model of the calculator.
(define-struct calc (stack ;; (listof number)
                     onscreen ;; number
                     ))
}|
}


What would be an example of a @racket[calc]?  How about a
calculator's initial state, when the stack is empty, and there's
a zero showing on-screen?  Let's add more to @filepath{calc.rkt}.

@codeblock|{
(define INIT-CALC
  (make-calc '() 0))
}|


Ok.  Let's try modelling the number-pressing behavior next.
Every number we press should adding more digits to the on-screen
display.  Let's define a function called @racket[insert-digit] to
do this.
@codeblock|{
;; insert-digit: calc number -> calc
;; Enters a digit on the calculator
(define (insert-digit calc digit)
  (make-calc (calc-stack calc)
             (+ (* (calc-onscreen calc) 10) 
                digit)))
}|

But we should write test cases, of course!  Let's make sure we
can start inserting digits into this calculator.  Let's add some
tests to the end of @filepath{calc.rkt}.

@racketblock[
(check-expect (insert-digit INIT-CALC 1)
              (make-calc '() 1))

(check-expect (insert-digit INIT-CALC 0)
              (make-calc '() 0))

(check-expect (insert-digit (insert-digit INIT-CALC 1)
                            2)
              (make-calc '() 12))
]

If we run this, we should see that our test cases are running fine
so far.

But... hmmm... it's a little awkward to keep nesting calls to
@racket[insert-digit] for our test cases.  Let's write a
quick-and-dirty harness to make it easier to press multiple
@emph{commands} into our calculator.  Let's call it
@racket[press]:

@margin-note{We'll amend our notion of what a @emph{command} is, in a moment.}
@codeblock|{
;; For the moment, a command is simply a number.

;; press: calc (listof command) -> calc
;; Convenience function doing multiple commands
;; into the calculator at once.
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
(check-expect (press INIT-CALC
                             '(0 0 3 1 4 1 5 9 2 6))
              (make-calc '()
                         31415926))

;; but of course, zero should be significant once we start
;; entering numbers.
(check-expect (press INIT-CALC
                             '(0 0 3 0 0))
              (make-calc '()
                         300))
}|


Ok, this looks good so far.  Let's add functionality to
@emph{push} a number into the stack.  Effectively, this will put
the number in the @racket[calc-onscreen] into the list of values held in @racket[calc-stack].


Here's an implementation of @racket[push-stack], which takes the
number onscreen and places it onto the stack.
@codeblock|{
;; push-stack: calc -> calc
;; Put the number in the onscreen window onto the stack,
;; and reset the onscreen back to 0.
(define (push-stack calc)
  (make-calc (cons (calc-onscreen calc)
                   (calc-stack calc))
             0))

(check-expect (push-stack INIT-CALC)
              (make-calc '(0)
                         0))

(check-expect (push-stack (push-stack INIT-CALC))
              (make-calc '(0 0)
                         0))

;; Slightly ugly test up ahead:
(check-expect (push-stack
               (press
                (push-stack
                 (press INIT-CALC '(3 1 4)))
                '(4 5 6)))
              (make-calc '(456 314)
                         0))
}|

The last test is somewhat ugly to read: we end up having to read
how it works inside-out.  We tried to make it easy to write tests
with multiple uses of @racket[insert-digit] by defining a
@racket[press] function: maybe we can expand on the idea of a
@emph{command} so it includes, not only numeric digits, but
things like @racket['push].  We'll revise our definition of
@racket[press] to work on both digits and the @racket['push]
command.


@codeblock|{
;; A command is a number, or the symbol 'push.

;; press: calc (listof command) -> calc
;; Convenience function doing multiple commands into the calculator at once.
(define (press calc commands)
  (foldl (lambda (cmd calc)
           (cond
            [(number? cmd)
             (insert-digit calc cmd)]
            [(eq? cmd 'push)
             (push-stack calc)]
            [else
             (error 'press "Unknown command: ~e" cmd)]))
         calc
         commands))

;; We rewrite the test to use 'push:
(check-expect (press INIT-CALC '(3 1 4 push 4 5 6 push))
              (make-calc '(456 314)
                         '(0)))
}|

Ok, that's a lot easier to read.  In fact, there's something
funny happening to @racket[press]: it's beginning to look more
than a simple test harness.  If we look at it with a twisted
enough perspective, we might dare to call it an
@emph{interpreter} for a very simple language.  Funny, that.


