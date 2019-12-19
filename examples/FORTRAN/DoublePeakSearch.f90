!set label "B_{DC,z} = 2.75 G" at 2.266,0.7
!set label "B_{DC,z} = 2.72 G" at 2.266,1.7
!set label "B_{DC,z} = 2.69 G" at 2.266,2.7
!set label "B_{DC,z} = 2.66 G" at 2.266,3.7
!set label "B_{DC,z} = 2.63 G" at 2.266,4.7
!set xrange [2.265:2.283]
!set xtics 2.265,0.003
!plot "datos_BdcX.dat" i 0 u 2:3 w lp lt 1 lw 2 , "" i 0 u 2:4 w lp lt 2 lw 2, "" i 0 u 2:5 w lp lt 3 lw 2, "" i 1 u 2:($3+1) w lp lt 1 lw 2, "" i 1 u 2:($4+1) w lp lt 2 lw 2, "" i 1 u 2:($5+1) w lp lt 3 lw 2,"" i 2 u 2:($3+2) w lp lt 1 lw 2, "" i 2 u 2:($4+2) w lp lt 2 lw 2, "" i 2 u 2:($5+2) w lp lt 3 lw 2,"" i 3 u 2:($3+3) w lp lt 1 lw 2, "" i 3 u 2:($4+3) w lp lt 2 lw 2, "" i 3 u 2:($5+3) w lp lt 3 lw 2,"" i 4 u 2:($3+4) w lp lt 1 lw 2, "" i 4 u 2:($4+4) w lp lt 2 lw 2, "" i 4 u 2:($5+4) w lp lt 3 lw 2,



PROGRAM MULTIMODEFLOQUET

  USE ATOMIC_PROPERTIES
  USE TYPES
  USE SUBINTERFACE
  USE SUBINTERFACE_LAPACK
  USE ARRAYS 
  USE FLOQUETINITINTERFACE


  IMPLICIT NONE
  TYPE(MODE),       DIMENSION(:),   ALLOCATABLE :: FIELDS
  TYPE(ATOM)                                       ID
  INTEGER,          DIMENSION(:),   ALLOCATABLE :: MODES_NUM
  INTEGER                                          TOTAL_FREQUENCIES,D_MULTIFLOQUET
  INTEGER                                          INFO,m,INDEX0,r,D_BARE
  DOUBLE PRECISION, DIMENSION(:),   ALLOCATABLE :: ENERGY,E_FLOQUET
  COMPLEX*16,       DIMENSION(:,:), ALLOCATABLE :: H__,U_F,U_AUX,U_B2D,U_F1,U_F2,U_F1_red,U_F2_red
  DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: P_AVG
  DOUBLE PRECISION                              :: T1,T2
 
  ! ===================================================
  !PARAMETERS REQUIRED TO DEFINE THE DRESSED BASIS
  COMPLEX*16,       DIMENSION(:,:), ALLOCATABLE :: U_FD           ! TRANSFORMATION FROM THE BARE TO THE DRESSED BASIS
  DOUBLE PRECISION, DIMENSION(:), ALLOCATABLE   :: E_DRESSED      ! DRESSED SPECTRUM
  INTEGER                                       :: DRESSINGFIELDS, DRESSINGFLOQUETDIMENSION! NUMBER OF DRESSING FIELDS
  INTEGER,          DIMENSION(:), ALLOCATABLE   :: DRESSINGFIELDS_INDICES ! IDENTITY OF THE DRESSING FIELDS

  INTEGER                              :: TOTAL_FREQUENCIES_,NM_,FIELD_INDEX
  TYPE(MODE), DIMENSION(:),ALLOCATABLE :: FIELDS_
  INTEGER,    DIMENSION(:),ALLOCATABLE :: MODES_NUM_
  ! ===================================================


  INTEGER :: t,o,N_
  DOUBLE PRECISION :: E_DOWN,E_UP
  DOUBLE PRECISION :: freq,pop

  OPEN(UNIT=3,file="Rb87_bareoscillation_DRIVER.dat", action="write")
  OPEN(UNIT=4,file="Rb87_dressedoscillation_DRIVER.dat", action="write")
!  OPEN(UNIT=1,FILE="datosExp.dat",ACTION="READ")

  N_=64
  INFO = 0
  CALL FLOQUETINIT(ID,'87Rb','B',INFO)
  ALLOCATE(ENERGY(SIZE(J_Z,1)))
  ALLOCATE(P_AVG(SIZE(J_z,1),SIZE(J_z,1)))
  ALLOCATE(U_AUX(SIZE(J_z,1),SIZE(J_z,1)))
  
  D_BARE = ID%D_BARE
  ALLOCATE(MODES_NUM(3))

  MODES_NUM(1) = 1 !(STATIC FIELD)
  MODES_NUM(2) = 1 !(DRIVING BY TWO HARMONICS)
  MODES_NUM(3) = 1 !(DRIVING BY A SECOND FREQUENCY)
  
  TOTAL_FREQUENCIES = SUM(MODES_NUM,1)
  ALLOCATE(FIELDS(TOTAL_FREQUENCIES))
  DO m=1,TOTAL_FREQUENCIES
     ALLOCATE(FIELDS(m)%V(ID%D_BARE,ID%D_BARE))
  END DO
  
  FIELDS(1)%X         = 0.263536E-4
  FIELDS(1)%Y         = 0.0!0.263536E-4
  FIELDS(1)%Z         = 2.63E-4
  FIELDS(1)%phi_x     = 0.0
  FIELDS(1)%phi_y     = 0.0
  FIELDS(1)%phi_z     = 0.0
  FIELDS(1)%omega     = 0.0
  FIELDS(1)%N_Floquet = 0

  FIELDS(2)%X         = 2.0*2.0*pi*0.350E6*hbar/(mu_B*0.5)
  FIELDS(2)%Y         = 0.0
  FIELDS(2)%Z         = 0.0
  FIELDS(2)%phi_x     = 0.0
  FIELDS(2)%phi_y     = 0.0
  FIELDS(2)%phi_z     = 0.0
  FIELDS(2)%omega     = 2.0*pi*2.27E6
  FIELDS(2)%N_Floquet = 6
  
  FIELDS(3)%X         = 2.0E-7
  FIELDS(3)%Y         = 2.0E-7
  FIELDS(3)%Z         = 2.0E-7
  FIELDS(3)%phi_x     = 0.0
  FIELDS(3)%phi_y     = 0.0!-0.11
  FIELDS(3)%phi_z     = 0.0
  FIELDS(3)%omega     = 0.0
  FIELDS(3)%N_Floquet = 2

  DO m=1,TOTAL_FREQUENCIES
     FIELDS(m)%X     = FIELDS(m)%X*exp(DCMPLX(0.0,1.0)*FIELDS(m)%phi_x)
     FIELDS(m)%Y     = FIELDS(m)%Y*exp(DCMPLX(0.0,1.0)*FIELDS(m)%phi_y)
     FIELDS(m)%Z     = FIELDS(m)%Z*exp(DCMPLX(0.0,1.0)*FIELDS(m)%phi_z)
     FIELDS(m)%OMEGA = HBAR*FIELDS(m)%OMEGA/A        
  END DO

  D_MULTIFLOQUET = ID%D_BARE
  DO r=1,TOTAL_FREQUENCIES
     D_MULTIFLOQUET = D_MULTIFLOQUET*(2*FIELDS(r)%N_Floquet+1)
  END DO

  !=================================================================================
  !==== DEFINITION OF THE DRESSING FIELDS AND DRESSED BASIS AND VARIABLES NEEDED TO DEFINE THE MICROMOTION OPERATOR
  !=================================================================================

  DRESSINGFIELDS = 2   ! NUMBER OF DRESSING FIELDS
  ALLOCATE(DRESSINGFIELDS_INDICES(DRESSINGFIELDS)) ! ARRAY THAT TELL US WHICH OF THE FIELD DEFINED ABOVE ARE THE DRESSING ONES
  DRESSINGFIELDS_INDICES(1) = 1 
  DRESSINGFIELDS_INDICES(2) = 2
  DRESSINGFLOQUETDIMENSION = ID%D_BARE ! EXTENDEND DIMENSION OF THE DRESSED BASIS
  DO m=2,DRESSINGFIELDS
    DRESSINGFLOQUETDIMENSION = DRESSINGFLOQUETDIMENSION*(2*FIELDS(DRESSINGFIELDS_INDICES(m))%N_FLOQUET + 1 )
  END DO
  ALLOCATE(U_FD(DRESSINGFLOQUETDIMENSION,DRESSINGFLOQUETDIMENSION))
  ALLOCATE(E_DRESSED(DRESSINGFLOQUETDIMENSION))
  CALL DRESSEDBASIS_SUBSET(ID,DRESSINGFLOQUETDIMENSION,DRESSINGFIELDS,SIZE(MODES_NUM,1),DRESSINGFIELDS_INDICES,MODES_NUM,FIELDS,&
       & U_FD,E_DRESSED,INFO) ! U_FD IS THE TRANSFORMATION OPERATOR BETWEEN THE BARE AND DRESSED BASIS, BOTH EXTENDED.
!  write(*,*) E_DRESSED
!!$  index0 = 3*fields(2)%n_FLOQUET
!!$  write(*,*) E_DRESSED(index0+1:INDEX0+3)
!!$  INDEX0 = 3*(2*FIELDS(2)%N_FLOQUET+1) + 5*FIELDS(2)%N_FLOQUET
!!$  write(*,*) E_DRESSED(index0+1:INDEX0+5)

  
  NM_ = DRESSINGFIELDS  ! NUMBER OF DRESSING MODES
  ALLOCATE(MODES_NUM_(NM_))
  DO r=1,NM_
     MODES_NUM_(r)=modes_num(DRESSINGFIELDS_INDICES(r)) ! NUMBER OF HARMONICS OF THE DRESSING MODES
  END DO
  
  TOTAL_FREQUENCIES_ = SUM(MODES_NUM_,1)  ! TOTAL NUMBER OF DRESSING FREQUENCIES
  ALLOCATE(FIELDS_(TOTAL_FREQUENCIES_))
  DO m=1,TOTAL_FREQUENCIES_
     ALLOCATE(FIELDS_(m)%V(ID%D_BARE,ID%D_BARE)) ! PREPARE SPACE TO SET THE DRESSING HAMILTONIAN COMPONENTS
  END DO
  
  FIELD_INDEX = 1
  DO r=1,DRESSINGFIELDS
     DO m=1,MODES_NUM_(r)
        FIELDS_(FIELD_INDEX) = FIELDS(DRESSINGFIELDS_INDICES(r)+m-1) ! IDENTIFY THE DRESSING FIELDS FROM THE COMPLETE LIST OF FIELDS
        FIELD_INDEX = FIELD_INDEX+1
     END DO
  END DO
  
  t = 3
  o = -1
  INDEX0 = 3*fields(2)%n_FLOQUET + 3
  E_DOWN = E_DRESSED(INDEX0)
  INDEX0 = (2*Fdown+1)*(2*FIELDS(2)%N_FLOQUET+1) + (2*Fup+1)*FIELDS(2)%N_FLOQUET + t - o*(2*Fup+1)
  E_UP   = E_DRESSED(INDEX0)


  !=================================================================================
  !== MULTIMODE FLOQUET DRESSED BASIS AND TIME-EVOLUTION OPERATOR IN THE BARE BASIS
  !=================================================================================
  
 CALL SETHAMILTONIANCOMPONENTS(ID,size(modes_num,1),total_frequencies,MODES_NUM,FIELDS,INFO)
 DO m=1,size(modes_num,1)
    !WRITE(*,*) FIELDS(m)%OMEGA
    !WRITE(*,*) FIELDS(m)%x
    !WRITE(*,*) FIELDS(m)%y
    !WRITE(*,*) FIELDS(m)%z
 !   CALL WRITE_MATRIX(ABS(FIELDS(m)%V))
 END DO
  
  !==== MICROMOTION OPERATORS EXTENDED BASIS
  ALLOCATE(U_F1(ID%D_BARE,SIZE(U_FD,1)))
  ALLOCATE(U_F2(ID%D_BARE,SIZE(U_FD,1)))
  !==== MICROMOTION OPERATOR 
  ALLOCATE(U_F1_red(ID%D_BARE,ID%D_BARE))
  ALLOCATE(U_F2_red(ID%D_BARE,ID%D_BARE))


  
  DO m=5,1,-1
     
     FIELDS(1)%Z         = 2.63E-4 + (m-1)*0.12E-4/4.0
     
     DO r=1,N_
        
!!$!========= FIND THE MULTIMODE FLOQUET SPECTRUM 
        
        FIELDS(3)%omega = 2.0 + FIELDS(2)%omega + 2*pi*2.265E6*hbar/A + (r-1.0)*2.0*pi*0.018E6*hbar/(A*N_)
        
        !E_UP - E_DOWN!(2*A - mu_B*0.5*500.0*abs(FIELDS(3)%x) + (r-1)*1000.0*mu_B*0.5*abs(FIELDS(3)%x)/128)/A! + (r-1)*2.0*abs(FIELDS(2)%x)/128)/hbar
        !write(*,*) 'ENERGIES',E_UP,E_DOWN,FIELDS(3)%OMEGA
        ! ===== EVALUATE TIME-EVOLUTION OPERATOR 
        
        T1 = 0.0
        T2 = 700.0E-6
        T2 = A*T2/hbar
        ! ===== EVALUATE TIME-EVOLUTION OPERATOR  IN THE BARE BASIS
        CALL TIMEEVOLUTIONOPERATOR(ID,D_BARE,SIZE(MODES_NUM,1),MODES_NUM,FIELDS,T1,T2,U_AUX,INFO) 
        !WRITE(3,*) (FIELDS(3)%OMEGA*A/HBAR)/(2*pi),1-abs(u_aux(3,3))**2
        
!!$     !=================================================================================
!!$     !== TRANSFORM THE TIME-EVOLUTION OPERATOR TO THE DRESSED BASIS
!!$     !=================================================================================
!!$        
!!$     !== BUILD THE TIME-DEPENDENT TRANSFORMATIONO BETWEEN THE BARE AND THE RF DRESSED BASIS       
        info =0         
        CALL MULTIMODEMICROMOTION(ID,SIZE(U_FD,1),NM_,MODES_NUM_,U_FD,E_DRESSED,ID%D_BARE,FIELDS_,T1,U_F1_red,INFO) 
        CALL MULTIMODEMICROMOTION(ID,SIZE(U_FD,1),NM_,MODES_NUM_,U_FD,E_DRESSED,ID%D_BARE,FIELDS_,T2,U_F2_red,INFO) 

!        CALL WRITE_MATRIX(ABS(U_F1_RED))
!        CALL WRITE_MATRIX(ABS(U_F2_RED))

        ! ---- CALCULATE THE TIME-EVOLUTION OPERATOR IN THE DRESSED BASIS USING THE PREVIOUSLY CALCULATED IN THE BARE BASIS
        U_AUX = MATMUL(TRANSPOSE(CONJG(U_F2_red)),MATMUL(U_AUX,U_F1_red)) ! HERE, P_AUX SHOULD BE OF DIMENSION D_BARE X D_BARE
        WRITE(*,*) REAL(1E4*FIELDS(1)%Z), 1E-6*((FIELDs(3)%OMEGA - 2.0 -fields(2)%omega)*A/hbar )/(2*pi),1-ABS(U_AUX(3,3))**2,&
             & 1-ABS(U_AUX(2,2))**2, 1-ABS(U_AUX(1,1))**2

!        WRITE(*,*) FIELDS(3)%OMEGA/(2*pi),t2,ABS(U_AUX)**2

     END DO
     write(*,*)
     write(*,*)
  END DO
  
END PROGRAM MULTIMODEFLOQUET

