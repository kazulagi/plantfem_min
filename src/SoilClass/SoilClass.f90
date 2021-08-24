module SoilClass
    use, intrinsic :: iso_fortran_env
    use fem
    use FertilizerClass
    implicit none

    type :: Soil_
        type(FEMDomain_) :: FEMDomain

        real(real64) :: depth
        real(real64) :: length
        real(real64) :: width
        integer(int32) :: num_x
        integer(int32) :: num_y
        integer(int32) :: num_z
        real(real64) :: x,y,z ! center coordinate

        ! ================
        ! Nutorient
        !------------
        real(real64) :: N_kg = 0.0d0
        real(real64) :: P_kg = 0.0d0
        real(real64) :: K_kg = 0.0d0
        real(real64) :: Ca_kg = 0.0d0
        real(real64) :: Mg_kg = 0.0d0
        real(real64) :: S_kg = 0.0d0
        !------------
        real(real64) :: Fe_kg = 0.0d0
        real(real64) :: Mn_kg = 0.0d0
        real(real64) :: B_kg = 0.0d0
        real(real64) :: Zn_kg = 0.0d0
        real(real64) :: Mo_kg = 0.0d0
        real(real64) :: Cu_kg = 0.0d0
        real(real64) :: Cl_kg = 0.0d0
        ! ================

        
        ! ================
        ! Soil phyisical parameters
        real(real64) :: C_N_ratio
        real(real64) :: EC
        ! ================


    contains
        procedure :: init => initSoil
        procedure :: create => initSoil
        procedure :: new => initSoil
        procedure :: resize => resizeSoil
        procedure :: rotate => rotateSoil
        procedure :: move => moveSoil
        procedure :: gmsh => gmshSoil
        procedure :: msh => mshSoil
        procedure :: fertilize => fertilizeSoil
        procedure :: diagnosis => diagnosisSoil
        procedure :: export => exportSoil
    end type

contains

! ################################################################
subroutine initSoil(obj,config,x_num,y_num,z_num)
    class(Soil_),intent(inout)::obj
    character(*),optional,intent(in) :: config
    integer(int32),optional,intent(in) :: x_num,y_num,z_num
    character(200) :: fn,conf,line
    real(real64) :: MaxThickness,Maxwidth,loc(3),vec(3),rot(3),zaxis(3),meshloc(3),meshvec(3)
    integer(int32) :: i,j,k,blcount,id,rmc,n,node_id,node_id2,elemid
    type(IO_) :: soilconf

    ! 節を生成するためのスクリプトを開く
    if(.not.present(config).or. index(config,".json")==0 )then
        ! デフォルトの設定を生成
        print *, "New soybean-configuration >> soilconfig.json"
        call soilconf%open("soilconfig.json")
        write(soilconf%fh,*) '{'
        write(soilconf%fh,*) '   "type": "soil",'
        write(soilconf%fh,*) '   "length": 1.00,'
        write(soilconf%fh,*) '   "width" : 1.00,'
        write(soilconf%fh,*) '   "depth" : 0.40,'
        write(soilconf%fh,*) '   "num_x": 10,'
        write(soilconf%fh,*) '   "num_y": 10,'
        write(soilconf%fh,*) '   "num_z":  4'
        write(soilconf%fh,*) '}'
        conf="soilconfig.json"
        call soilconf%close()
    else
        conf = trim(config)
    endif
    
    call soilconf%open(trim(conf))
    blcount=0
    do
        read(soilconf%fh,'(a)') line
        print *, trim(line)
        if( adjustl(trim(line))=="{" )then
            blcount=1
            cycle
        endif
        if( adjustl(trim(line))=="}" )then
            exit
        endif
        
        if(blcount==1)then
            
            if(index(line,"type")/=0 .and. index(line,"soil")==0 )then
                print *, "ERROR: This config-file is not for soybean"
                return
            endif


            if(index(line,"length")/=0 )then
                ! 生育ステージ
                rmc=index(line,",")
                ! カンマがあれば除く
                if(rmc /= 0)then
                    line(rmc:rmc)=" "
                endif
                id = index(line,":")
                read(line(id+1:),*) obj%length
            endif


            if(index(line,"width")/=0 )then
                ! 生育ステージ
                rmc=index(line,",")
                ! カンマがあれば除く
                if(rmc /= 0)then
                    line(rmc:rmc)=" "
                endif
                id = index(line,":")
                read(line(id+1:),*) obj%width
            endif

            if(index(line,"depth")/=0 )then
                ! 生育ステージ
                rmc=index(line,",")
                ! カンマがあれば除く
                if(rmc /= 0)then
                    line(rmc:rmc)=" "
                endif
                id = index(line,":")
                read(line(id+1:),*) obj%depth
            endif


            if(index(line,"num_y")/=0 )then
                ! 生育ステージ
                rmc=index(line,",")
                ! カンマがあれば除く
                if(rmc /= 0)then
                    line(rmc:rmc)=" "
                endif
                id = index(line,":")
                read(line(id+1:),*) obj%num_y
            endif


            if(index(line,"num_z")/=0 )then
                ! 生育ステージ
                rmc=index(line,",")
                ! カンマがあれば除く
                if(rmc /= 0)then
                    line(rmc:rmc)=" "
                endif
                id = index(line,":")
                read(line(id+1:),*) obj%num_z
            endif

            if(index(line,"num_x")/=0 )then
                ! 生育ステージ
                rmc=index(line,",")
                ! カンマがあれば除く
                if(rmc /= 0)then
                    line(rmc:rmc)=" "
                endif
                id = index(line,":")
                read(line(id+1:),*) obj%num_x
            endif

            cycle

        endif

    enddo
    call soilconf%close()

    if(present(x_num) )then
        obj%num_x = x_num
    endif
    
    if(present(y_num) )then
        obj%num_y = y_num
    endif

    if(present(z_num) )then
        obj%num_z = z_num
    endif

    call obj%FEMdomain%create(meshtype="rectangular3D",x_num=obj%num_x,&
    y_num=obj%num_y,z_num=obj%num_z,&
    x_len=obj%length,y_len=obj%width,z_len=obj%depth)

    call obj%femdomain%move(x=-obj%length/2.0d0,&
    y=-obj%width/2.0d0,z=-obj%depth)


end subroutine
! ################################################################


! ################################################################
subroutine fertilizeSoil(obj,Fertilizer,N_kg,P_kg,K_kg,Ca_kg,Mg_kg,S_kg,Fe_kg,&
    Mn_kg,B_kg,Zn_kg,Mo_kg,Cu_kg,Cl_kg)
    
    class(Soil_),intent(inout)::obj
    type(Fertilizer_),optional,intent(in) :: Fertilizer


    ! ================
    real(real64),optional,intent(in) :: N_kg
    real(real64),optional,intent(in) :: P_kg
    real(real64),optional,intent(in) :: K_kg
    real(real64),optional,intent(in) :: Ca_kg
    real(real64),optional,intent(in) :: Mg_kg
    real(real64),optional,intent(in) :: S_kg
    ! ================
    real(real64),optional,intent(in) :: Fe_kg
    real(real64),optional,intent(in) :: Mn_kg
    real(real64),optional,intent(in) :: B_kg
    real(real64),optional,intent(in) :: Zn_kg
    real(real64),optional,intent(in) :: Mo_kg
    real(real64),optional,intent(in) :: Cu_kg
    real(real64),optional,intent(in) :: Cl_kg
    ! ================


    if(present(Fertilizer) )then
        obj%N_kg = obj%N_kg + Fertilizer%N_kg
        obj%P_kg = obj%P_kg + Fertilizer%P_kg
        obj%K_kg = obj%K_kg + Fertilizer%K_kg
        obj%Ca_kg = obj%Ca_kg + Fertilizer%Ca_kg
        obj%Mg_kg = obj%Mg_kg + Fertilizer%Mg_kg
        obj%S_kg = obj%S_kg + Fertilizer%S_kg
        obj%Fe_kg = obj%Fe_kg + Fertilizer%Fe_kg
        obj%Mn_kg = obj%Mn_kg + Fertilizer%Mn_kg
        obj%B_kg = obj%B_kg + Fertilizer%B_kg
        obj%Zn_kg = obj%Zn_kg + Fertilizer%Zn_kg
        obj%Mo_kg = obj%Mo_kg + Fertilizer%Mo_kg
        obj%Cu_kg = obj%Cu_kg + Fertilizer%Cu_kg
        obj%Cl_kg = obj%Cl_kg + Fertilizer%Cl_kg
        return
    endif

    obj%N_kg    = input(default=0.0d0,option=N_kg)
    obj%P_kg    = input(default=0.0d0,option=P_kg)
    obj%K_kg    = input(default=0.0d0,option=K_kg)
    obj%Ca_kg   = input(default=0.0d0,option=Ca_kg)
    obj%Mg_kg   = input(default=0.0d0,option=Mg_kg)
    obj%S_kg    = input(default=0.0d0,option=S_kg)
    obj%Fe_kg   = input(default=0.0d0,option=Fe_kg)
    obj%Mn_kg   = input(default=0.0d0,option=Mn_kg)
    obj%B_kg    = input(default=0.0d0,option=B_kg)
    obj%Zn_kg   = input(default=0.0d0,option=Zn_kg)
    obj%Mo_kg   = input(default=0.0d0,option=Mo_kg)
    obj%Cu_kg   = input(default=0.0d0,option=Cu_kg)
    obj%Cl_kg   = input(default=0.0d0,option=Cl_kg)

end subroutine
! ################################################################

! ################################################################
subroutine exportSoil(obj,FileName,format,objID)
    class(Soil_),intent(inout)::obj
    integer(int32),optional,intent(inout) :: objID
    character(*),intent(in)::FileName
    character(*),optional,intent(in) :: format

    if(present(format) )then
        if(format==".geo" .or. format=="geo" )then
            open(15,file=FileName)
            write(15,'(A)') "//+"
            write(15,'(A)') 'SetFactory("OpenCASCADE");'
            write(15,*) "Box(",input(default=1,option=objID),") = {",&
            obj%x   ,",", obj%y  ,",", obj%z ,   ",",&
            obj%width                ,",", obj%length               ,",", obj%depth ,"};"
            close(15)
            objID=objID+1
        endif
    endif
end subroutine
! ################################################################

subroutine diagnosisSoil(obj,FileName)
    class(Soil_),intent(inout) :: obj
    character(*),optional,intent(in)::FileName

    print *, "======================="
    print *, "Soil diagnosis"
    print *, "-----------------------"
    print *, "Total area ", trim(adjustl(fstring(obj%width*obj%length)))//" (cm^2)"
    print *, "Total area ",trim(adjustl(fstring(obj%width/100.0d0*obj%length/100.0d0)))//" (m^2)"
    print *, "Total area ",trim(adjustl(fstring(obj%width/100.0d0*obj%length/100.0d0/100.0d0)))//" (a)"
    print *, "Total area ",trim(adjustl(fstring(obj%width/100.0d0*obj%length/100.0d0/100.0d0/100.0d0)))//" (ha)"
    print *, "Total N  ",trim(adjustl(fstring(obj%N_kg )))//" (kg)"   
    print *, "Total P  ",trim(adjustl(fstring(obj%P_kg )))//" (kg)"   
    print *, "Total K  ",trim(adjustl(fstring(obj%K_kg )))//" (kg)"   
    print *, "Total Ca ",trim(adjustl(fstring(obj%Ca_kg)))//" (kg)"   
    print *, "Total Mg ",trim(adjustl(fstring(obj%Mg_kg)))//" (kg)"   
    print *, "Total S  ",trim(adjustl(fstring(obj%S_kg )))//" (kg)"   
    print *, "Total Fe ",trim(adjustl(fstring(obj%Fe_kg)))//" (kg)"   
    print *, "Total Mn ",trim(adjustl(fstring(obj%Mn_kg)))//" (kg)"   
    print *, "Total B  ",trim(adjustl(fstring(obj%B_kg )))//" (kg)"   
    print *, "Total Zn ",trim(adjustl(fstring(obj%Zn_kg)))//" (kg)"   
    print *, "Total Mo ",trim(adjustl(fstring(obj%Mo_kg)))//" (kg)"   
    print *, "Total Cu ",trim(adjustl(fstring(obj%Cu_kg)))//" (kg)"   
    print *, "Total Cl ",trim(adjustl(fstring(obj%Cl_kg)))//" (kg)"   
    print *, "-----------------------"
    print *, "Total N  ", trim(adjustl(fstring(obj%N_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"    
    print *, "Total P  ", trim(adjustl(fstring(obj%P_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"    
    print *, "Total K  ", trim(adjustl(fstring(obj%K_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"    
    print *, "Total Ca ", trim(adjustl(fstring(obj%Ca_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total Mg ", trim(adjustl(fstring(obj%Mg_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total S  ", trim(adjustl(fstring(obj%S_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"    
    print *, "Total Fe ", trim(adjustl(fstring(obj%Fe_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total Mn ", trim(adjustl(fstring(obj%Mn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total B  ", trim(adjustl(fstring(obj%B_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"    
    print *, "Total Zn ", trim(adjustl(fstring(obj%Zn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total Mo ", trim(adjustl(fstring(obj%Mo_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total Cu ", trim(adjustl(fstring(obj%Cu_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "Total Cl ", trim(adjustl(fstring(obj%Cl_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*1000.0)))//" (kg/10a)"   
    print *, "-----------------------"
    print *, "Total N  ",trim(adjustl(fstring(obj%N_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)"  
    print *, "Total P  ",trim(adjustl(fstring(obj%P_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)"  
    print *, "Total K  ",trim(adjustl(fstring(obj%K_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)"  
    print *, "Total Ca ",trim(adjustl(fstring(obj%Ca_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total Mg ",trim(adjustl(fstring(obj%Mg_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total S  ",trim(adjustl(fstring(obj%S_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)"  
    print *, "Total Fe ",trim(adjustl(fstring(obj%Fe_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total Mn ",trim(adjustl(fstring(obj%Mn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total B  ",trim(adjustl(fstring(obj%B_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)"  
    print *, "Total Zn ",trim(adjustl(fstring(obj%Zn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total Mo ",trim(adjustl(fstring(obj%Mo_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total Cu ",trim(adjustl(fstring(obj%Cu_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)" 
    print *, "Total Cl ",trim(adjustl(fstring(obj%Cl_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10000.0d0)))//" (kg/ha)"    
    print *, "======================="

    if(present(FileName) )then
        open(16,file=FileName)
        
        write(16,*) "======================="
        write(16,*) "Soil diagnosis"
        write(16,*) "-----------------------"
        write(16,*) "Total N  (kg)",obj%N_kg    
        write(16,*) "Total P  (kg)",obj%P_kg    
        write(16,*) "Total K  (kg)",obj%K_kg    
        write(16,*) "Total Ca (kg)",obj%Ca_kg   
        write(16,*) "Total Mg (kg)",obj%Mg_kg   
        write(16,*) "Total S  (kg)",obj%S_kg    
        write(16,*) "Total Fe (kg)",obj%Fe_kg   
        write(16,*) "Total Mn (kg)",obj%Mn_kg   
        write(16,*) "Total B  (kg)",obj%B_kg    
        write(16,*) "Total Zn (kg)",obj%Zn_kg   
        write(16,*) "Total Mo (kg)",obj%Mo_kg   
        write(16,*) "Total Cu (kg)",obj%Cu_kg   
        write(16,*) "Total Cl (kg)",obj%Cl_kg   
        write(16,*) "-----------------------"
        write(16,*) "Total N  (kg/10a)",obj%N_kg /(obj%width/100.0d0)/(obj%length/100.0d0)    
        write(16,*) "Total P  (kg/10a)",obj%P_kg /(obj%width/100.0d0)/(obj%length/100.0d0)    
        write(16,*) "Total K  (kg/10a)",obj%K_kg /(obj%width/100.0d0)/(obj%length/100.0d0)    
        write(16,*) "Total Ca (kg/10a)",obj%Ca_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total Mg (kg/10a)",obj%Mg_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total S  (kg/10a)",obj%S_kg /(obj%width/100.0d0)/(obj%length/100.0d0)    
        write(16,*) "Total Fe (kg/10a)",obj%Fe_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total Mn (kg/10a)",obj%Mn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total B  (kg/10a)",obj%B_kg /(obj%width/100.0d0)/(obj%length/100.0d0)    
        write(16,*) "Total Zn (kg/10a)",obj%Zn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total Mo (kg/10a)",obj%Mo_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total Cu (kg/10a)",obj%Cu_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "Total Cl (kg/10a)",obj%Cl_kg/(obj%width/100.0d0)/(obj%length/100.0d0)   
        write(16,*) "-----------------------"
        write(16,*) "Total N  (kg/ha)",obj%N_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0    
        write(16,*) "Total P  (kg/ha)",obj%P_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0    
        write(16,*) "Total K  (kg/ha)",obj%K_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0    
        write(16,*) "Total Ca (kg/ha)",obj%Ca_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total Mg (kg/ha)",obj%Mg_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total S  (kg/ha)",obj%S_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0    
        write(16,*) "Total Fe (kg/ha)",obj%Fe_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total Mn (kg/ha)",obj%Mn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total B  (kg/ha)",obj%B_kg /(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0    
        write(16,*) "Total Zn (kg/ha)",obj%Zn_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total Mo (kg/ha)",obj%Mo_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total Cu (kg/ha)",obj%Cu_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0   
        write(16,*) "Total Cl (kg/ha)",obj%Cl_kg/(obj%width/100.0d0)/(obj%length/100.0d0)*10.0d0      
        write(16,*) "======================="
        close(16)
    endif
end subroutine


! ########################################
subroutine gmshSoil(obj,name)
    class(Soil_),intent(inout) :: obj
    character(*),intent(in) :: name

    call obj%femdomain%gmsh(Name=name)
    
end subroutine
! ########################################

! ########################################
subroutine resizeSoil(obj,x,y,z)
    class(Soil_),intent(inout) :: obj
    real(real64),optional,intent(in) :: x,y,z

    call obj%femdomain%resize(x=x,y=y,z=z)

end subroutine
! ########################################

! ########################################
subroutine rotateSoil(obj,x,y,z)
    class(Soil_),intent(inout) :: obj
    real(real64),optional,intent(in) :: x,y,z

    call obj%femdomain%rotate(x=x,y=y,z=z)
    
end subroutine
! ########################################


! ########################################
subroutine moveSoil(obj,x,y,z)
    class(Soil_),intent(inout) :: obj
    real(real64),optional,intent(in) :: x,y,z

    call obj%femdomain%move(x=x,y=y,z=z)
    
end subroutine
! ########################################


! ########################################
subroutine mshSoil(obj,name)
    class(Soil_),intent(inout) :: obj
    character(*),intent(in) :: name

    call obj%femdomain%msh(Name=name)
    
end subroutine
! ########################################

end module