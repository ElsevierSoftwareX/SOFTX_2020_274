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



 
  OPEN(UNIT=3,file="qubit_bareoscillation_DRIVER.dat", action="write")
  OPEN(UNIT=4,file="qubit_dressedoscillation_DRIVER.dat", action="write")


  INFO = 0
  CALL FLOQUETINIT(ID,'qubit',INFO)
  ALLOCATE(ENERGY(SIZE(J_Z,1)))
  ALLOCATE(H__(SIZE(J_z,1),SIZE(J_z,1)))
  ALLOCATE(P_AVG(SIZE(J_z,1),SIZE(J_z,1)))
  ALLOCATE(U_AUX(SIZE(J_z,1),SIZE(J_z,1)))
  H__ = J_z
  CALL LAPACK_FULLEIGENVALUES(H__,TOTAL_STATES_LSI,Energy,INFO)
  DEALLOCATE(H__)
  DEALLOCATE(ENERGY)
  
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
  
  FIELDS(1)%X         = 0.0
  FIELDS(1)%Y         = 0.0
  FIELDS(1)%Z         = 1.0
  FIELDS(1)%phi_x     = 0.0
  FIELDS(1)%phi_y     = 0.0
  FIELDS(1)%phi_z     = 0.0
  FIELDS(1)%omega     = 0.0
  FIELDS(1)%N_Floquet = 0

  FIELDS(2)%X         = 0.125
  FIELDS(2)%Y         = 0.0
  FIELDS(2)%Z         = 0.0
  FIELDS(2)%phi_x     = 0.0
  FIELDS(2)%phi_y     = 0.0
  FIELDS(2)%phi_z     = 0.0
  FIELDS(2)%omega     = 1.0
  FIELDS(2)%N_Floquet = 5
  
  FIELDS(3)%X         = 0.125*FIELDS(2)%X/2.0
  FIELDS(3)%Y         = 0.0
  FIELDS(3)%Z         = 0.125*FIELDS(2)%X/2.0
  FIELDS(3)%phi_x     = 0.0
  FIELDS(3)%phi_y     = 0.0
  FIELDS(3)%phi_z     = 0.0
  FIELDS(3)%omega     = FIELDS(2)%X/2.0
  FIELDS(3)%N_Floquet = 3

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
  !CALL WRITE_MATRIX(ABS(U_FD))
  INDEX0 = ID%D_BARE*FIELDS(2)%N_FLOQUET 
  !write(*,*) E_DRESSED(INDEX0+1:INDEX0+ID%D_BARE)

  
  NM_ = DRESSINGFIELDS  ! NUMBER OF DRESSIN MODES
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
  
  !=================================================================================
  !== MULTIMODE FLOQUET DRESSED BASIS AND TIME-EVOLUTION OPERATOR IN THE BARE BASIS
  !=================================================================================
  !WRITE(*,*) t2,ABS(U_AUX)**2
  
  CALL SETHAMILTONIANCOMPONENTS(ID,size(modes_num,1),total_frequencies,MODES_NUM,FIELDS,INFO)
  
  !==== MICROMOTION OPERATORS EXTENDED BASIS
  ALLOCATE(U_F1(ID%D_BARE,SIZE(U_FD,1)))
  ALLOCATE(U_F2(ID%D_BARE,SIZE(U_FD,1)))
  !==== MICROMOTION OPERATOR 
  ALLOCATE(U_F1_red(ID%D_BARE,ID%D_BARE))
  ALLOCATE(U_F2_red(ID%D_BARE,ID%D_BARE))

  !DO m=1,TOTAL_FREQUENCIES
  !   CALL WRITE_MATRIX(REAL(FIELDS(m)%V))
  !END DO

  DO r=1,64

!!$!========= FIND THE MULTIMODE FLOQUET SPECTRUM 
      
     FIELDS(3)%omega     = FIELDS(2)%X/4.0 + (r-1)*FIELDS(2)%X/64
     
     ! ===== EVALUATE TIME-EVOLUTION OPERATOR 

     T1 = 0.0
     DO m=64,64!128,128         
        T2 = (m-1)*16.0*100.0/128
        
        ! ===== EVALUATE TIME-EVOLUTION OPERATOR  IN THE BARE BASIS
        CALL TIMEEVOLUTIONOPERATOR(ID,D_BARE,SIZE(MODES_NUM,1),SIZE(MODES_NUM,1),MODES_NUM,FIELDS,T1,T2,U_AUX,INFO) 
        WRITE(3,*) FIELDS(3)%OMEGA,t2,ABS(U_AUX)**2
        
!!$     !=================================================================================
!!$     !== TRANSFORM THE TIME-EVOLUTION OPERATOR TO THE DRESSED BASIS
!!$     !=================================================================================
!!$        
!!$     !== BUILD THE TIME-DEPENDENT TRANSFORMATIONO BETWEEN THE BARE AND THE RF DRESSED BASIS       
        info =0         
        CALL MULTIMODEMICROMOTION(ID,SIZE(U_FD,1),NM_,MODES_NUM_,U_FD,E_DRESSED,ID%D_BARE,FIELDS_,T1,U_F1_red,INFO) 
        CALL MULTIMODEMICROMOTION(ID,SIZE(U_FD,1),NM_,MODES_NUM_,U_FD,E_DRESSED,ID%D_BARE,FIELDS_,T2,U_F2_red,INFO) 
        
        ! ---- CALCULATE THE TIME-EVOLUTION OPERATOR IN THE DRESSED BASIS USING THE PREVIOUSLY CALCULATED IN THE BARE BASIS
        U_AUX = MATMUL(TRANSPOSE(CONJG(U_F2_red)),MATMUL(U_AUX,U_F1_red)) ! HERE, P_AUX SHOULD BE OF DIMENSION D_BARE X D_BARE
        WRITE(4,*) FIELDS(3)%OMEGA,t2,ABS(U_AUX)**2

     END DO
  END DO
  
END PROGRAM MULTIMODEFLOQUET

!!$SUBROUTINE DRESSEDBASIS(ID,DRESSINGFLOQUETDIMENSION,DRESSINGFIELDS,NM,DRESSINGFIELDS_INDICES,MODES_NUM,FIELDS,U_FD,E_DRESSED,INFO)
!!$
!THIS SUBROUTINES CALCULATES THE TRANSFORMATION BETWEEN THE BARE BASIS TO THE DRESSED BASIS DEFINDED BY A SUBSET OF THE DRIVING FIELDS.

! ID (IN)                      : TYPE OF QUATUM SYSTEM
! DRESSINGFLOQUETDIMENSION(IN) : DIMENSION OF THE DRESSED FLOQUET HILBERT SPACE
! DRESSINGFIELDS (IN)          : NUMBER OF DRESSING FIELDS
! NM (IN)                      : NUMBER OF MODES == NUMBER OF DRIVING FIELDS
! DRESSINGFIELDS_INDICES       : OUT OF ALL THE DRIVING FIELDS, THIS VECTOR INDICATES THE INDEX OF THE DRESSING FIELD
! MODES_NUM                    : VECTOR INDICATING THE NUMBER OF HARMONICS OF EACH DRESSING FIELD
! FIELDS (IN)                  : AMPLITUDE, FREQUENCY AND PHASES OF ALL DRIVING FIELDS
! U_FD (OUT)                   : THIS IS THE TRANSFORMATION WE ARE LOOKING FOR
! E_DRESSED (OUT)              : DRESSED ENERGIES
! INFO (INOUT)                 : INFO = 0 MEANS SUCESS
!!$               
!!$
!!$  USE ATOMIC_PROPERTIES
!!$  USE TYPES
!!$  USE SUBINTERFACE
!!$  USE SUBINTERFACE_LAPACK
!!$  USE FLOQUETINIT_ 
!!$  USE ARRAYS 
!!$
!!$  IMPLICIT NONE
!!$  TYPE(MODE), DIMENSION(NM),                             INTENT(IN)    :: FIELDS
!!$  TYPE(ATOM),                                            INTENT(IN)    :: ID
!!$  INTEGER,    DIMENSION(DRESSINGFIELDS),                 INTENT(IN)    :: DRESSINGFIELDS_INDICES
!!$  INTEGER,    DIMENSION(NM),                             INTENT(IN)    :: MODES_NUM
!!$  COMPLEX*16, DIMENSION(DRESSINGFLOQUETDIMENSION,DRESSINGFLOQUETDIMENSION),       INTENT(OUT)   :: U_FD
!!$  DOUBLE PRECISION, DIMENSION(DRESSINGFLOQUETDIMENSION), INTENT(OUT)   :: E_DRESSED
!!$  INTEGER,                                               INTENT(IN)    :: DRESSINGFLOQUETDIMENSION,DRESSINGFIELDS,NM
!!$  INTEGER,                                               INTENT(INOUT) :: INFO
!!$
!!$
!!$  INTEGER r,m,FIELD_INDEX
!!$  INTEGER ND_,NM_
!!$  INTEGER TOTAL_FREQUENCIES_
!!$  !TYPE(MODE), DIMENSION(DRESSINGFIELDS) :: FIELDS_
!!$  TYPE(MODE), DIMENSION(:),ALLOCATABLE  :: FIELDS_
!!$  INTEGER,    DIMENSION(DRESSINGFIELDS) :: MODES_NUM_
!!$
!!$  !NM_ = DRESSINGFIELDS
!!$  !ND_ = DRESSINGFIELDS
!!$
!!$  DO r=1,DRESSINGFIELDS
!!$     MODES_NUM_(r)=modes_num(DRESSINGFIELDS_INDICES(r))
!!$     !FIELDS_(r) = FIELDS(DRESSINGFIELDS_INDICES(r))
!!$  END DO
!!$
!!$  TOTAL_FREQUENCIES_ = SUM(MODES_NUM_,1)
!!$  ALLOCATE(FIELDS_(TOTAL_FREQUENCIES_))
!!$  DO m=1,TOTAL_FREQUENCIES_
!!$     ALLOCATE(FIELDS_(m)%V(ID%D_BARE,ID%D_BARE))
!!$  END DO
!!$
!!$
!!$  FIELD_INDEX = 1
!!$  DO r=1,DRESSINGFIELDS
!!$     DO m=1,MODES_NUM_(r)
!!$        FIELDS_(FIELD_INDEX) = FIELDS(DRESSINGFIELDS_INDICES(r)+m-1)
!!$        FIELD_INDEX = FIELD_INDEX+1
!!$     END DO
!!$  END DO
!!$  
!!$
!!$  !CALL SETHAMILTONIANCOMPONENTS(ID,NM_,ND_,MODES_NUM_,FIELDS_,INFO)
!!$  CALL SETHAMILTONIANCOMPONENTS(ID,size(modes_num_,1),total_frequencies_,MODES_NUM_,FIELDS_,INFO)
!!$
!!$  !--- FIND THE MULTIMODE FLOQUET SPECTRUM 
!!$!  DEALLOCATE(H_FLOQUET)
!!$  !CALL MULTIMODEFLOQUETMATRIX(ID,NM_,ND_,MODES_NUM_,FIELDS_,INFO)
!!$  CALL MULTIMODEFLOQUETMATRIX(ID,size(modes_num_,1),total_frequencies_,MODES_NUM_,FIELDS_,INFO)
!!$  !call write_matrix(real(H_floquet))
!!$  E_DRESSED = 0.0  
!!$  CALL LAPACK_FULLEIGENVALUES(H_FLOQUET,SIZE(H_FLOQUET,1),E_DRESSED,INFO)
!!$  WRITE(*,*) SIZE(H_FLOQUET,1), SIZE(U_FD,1),size(e_dressed,1)
!!$  U_FD = H_FLOQUET ! FOURIER DECOMPOSITION OF THE STATES DRESSED BY MODE NUMBER 
!!$  DEALLOCATE(H_FLOQUET)
!!$
!!$END SUBROUTINE DRESSEDBASIS
