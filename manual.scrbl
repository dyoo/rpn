#lang scribble/manual

@title{Writing an RPN Calculator in Whalesong}
@author+email["dyoo@hashcollision.org"]{Danny Yoo}

Let's try to make a simple
@link["http://en.wikipedia.org/wiki/Reverse_Polish_notation"]{Reverse
Polish Notation} (RPN) calculator.  It's one of those toy
examples that are, at the very least, slightly more interesting
than @racket[factorial], so let's see what it looks like in
Whalesong.



@section{The Model}
First, let's talk about a model of an RPN calculator.  There's a
notion of what digits are showing on the screen of the
calculator, as well as some notion of the calculator's stack.
Let's try coding that up.


@codeblock|{
#lang whalesong/base

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