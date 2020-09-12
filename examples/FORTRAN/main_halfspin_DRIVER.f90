
PROGRAM MULTIMODEFLOQUET

  USE ATOMIC_PROPERTIES
  USE TYPES
  USE SUBINTERFACE
  USE SUBINTERFACE_LAPACK
  USE FLOQUETINITINTERFACE
  USE ARRAYS 


  IMPLICIT NONE
  TYPE(MODE),       DIMENSION(:),   ALLOCATABLE :: FIELDS
  TYPE(ATOM)                                       ID
  INTEGER,          DIMENSION(:),   ALLOCATABLE :: MODES_NUM
  INTEGER                                          TOTAL_FREQUENCIES,D_BARE
  INTEGER                                          INFO,m,INDEX0,r
  DOUBLE PRECISION, DIMENSION(:),   ALLOCATABLE :: ENERGY,E_FLOQUET
  COMPLEX*16,       DIMENSION(:,:), ALLOCATABLE :: H__,U_F,U_AUX,U_B2D
  DOUBLE PRECISION, DIMENSION(:,:), ALLOCATABLE :: P_AVG
  DOUBLE PRECISION                              :: T1,T2






  INTEGER M_,N_
  OPEN(UNIT=3,FILE="halfspin_oscillation_DRIVER.dat",ACTION="WRITE")


  INFO = 0
  CALL FLOQUETINIT(ID,'spin',0.1D1,INFO)  

  D_BARE = ID%D_BARE
  ALLOCATE(P_AVG(D_BARE,D_BARE))
  ALLOCATE(U_AUX(D_BARE,D_BARE))
!  ALLOCATE(U_B2D(D_BARE,D_BARE))

  ALLOCATE(MODES_NUM(2))
  
  MODES_NUM(1) = 1 !(STATIC FIELD)
  MODES_NUM(2) = 1 !(DRIVING BY ONE HARMONIC)
  
  TOTAL_FREQUENCIES = SUM(MODES_NUM,1)
  ALLOCATE(FIELDS(TOTAL_FREQUENCIES))
  DO m=1,TOTAL_FREQUENCIES
     ALLOCATE(FIELDS(m)%V(ID%D_BARE,ID%D_BARE))
  END DO
  
  FIELDS(1)%X    = 0.0
  FIELDS(1)%Y    = 0.0
  FIELDS(1)%Z    = 1.0
  FIELDS(1)%phi_x = 0.0
  FIELDS(1)%phi_y = 0.0
  FIELDS(1)%phi_z = 0.0
  FIELDS(1)%omega = 0.0
  FIELDS(1)%N_Floquet = 0

  FIELDS(2)%X     = 2.0
  FIELDS(2)%Y     = 0.0
  FIELDS(2)%Z     = 0.0
  FIELDS(2)%phi_x = 0.0
  FIELDS(2)%phi_y = 0.0
  FIELDS(2)%phi_z = 0.0
  FIELDS(2)%omega = 1.0
  FIELDS(2)%N_Floquet = 20

  N_=16
  M_=16
  DO m=1,N_

     ! --- SET DRIVING PARAMETERS 
     FIELDS(2)%omega = 0.2 + (m-1)*2.0/N_

         
     !--- EVALUATE TIME-EVOLUTION OPERATOR IN THE BARE BASIS
     T1 = 0.0
     DO r=1,M_
        T2 = r*32.0*4.0*atan(1.0)/M_
        CALL TIMEEVOLUTIONOPERATOR(ID,D_BARE,SIZE(MODES_NUM,1),TOTAL_FREQUENCIES,MODES_NUM,FIELDS,T1,T2,U_AUX,INFO) 
        P_AVG = ABS(U_AUX)**2
        WRITE(3,*) t2,FIELDS(2)%OMEGA,ABS(U_AUX)**2
     END DO
     WRITE(3,*)
  END DO
  
  
END PROGRAM MULTIMODEFLOQUET

