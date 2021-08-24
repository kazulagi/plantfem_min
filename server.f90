use plantfem

implicit none

type(IO_) :: f

call f%open("test.txt" , "w")
call f%write("hello")
call f%close()

end