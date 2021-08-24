use plantfem

implicit none

type(Soybean_) :: soy(10)

do i_i = 1, 10
    call soy(i_i)%init(config="Tutorial/playon_obj/realSoybeanConfig.json") 
enddo

do i_i = 1, 10
    print *, "Volume: ", soy(i_i)%getVolume()
enddo

end