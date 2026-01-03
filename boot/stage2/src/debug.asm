%macro bbrk 0
%ifdef DEBUG
xchg bx, bx
%endif
%endmacro
