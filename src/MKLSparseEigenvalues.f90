SUBROUTINE MKLSPARSE_FULLEIGENVALUES(D,DV,VALUES,ROW_INDEX,COLUMN,E_L,E_R,E_FLOQUET,U_F,INFO)

!CALCULATES THE ENERGY SPECTRUM OF THE MATRIX REPRESENTED BY VALUES, ROW_INDEX AND COLUMN
! D (IN), MATRIX DIMENSION == NUMBER OF EIGENVALUES
! DV (IN), NUMBER OF VALUES != 0
! VALUES (IN) ARRAY OF VALUES
! ROW_INDEX (IN), ARRAY OF INDICES
! COLUMN (IN),    ARRAY OF COLUMN NUMBERS
! E_L (IN),       LEFT BOUNDARY OF THE SEARCH INTERVAL
! E_R (IN),       RIGHT BOUNDARY OF THE SEARCH INTERVAL
! E_FLOQUET (OUT), ARRAY OF EIGENVALUES
! INFO     (INOUT)  ERROR FLAG

  USE FEAST
  IMPLICIT NONE
  INTEGER,                          INTENT(IN)    :: D,DV
  COMPLEX*16,       DIMENSION(DV),  INTENT(INOUT) :: VALUES
  INTEGER,          DIMENSION(DV),  INTENT(INOUT) :: COLUMN
  INTEGER,          DIMENSION(D+1), INTENT(INOUT) :: ROW_INDEX
  DOUBLE PRECISION,                 INTENT(IN)    :: E_L,E_R
  DOUBLE PRECISION, DIMENSION(D),   INTENT(OUT)   :: E_FLOQUET
  COMPLEX*16,       DIMENSION(D,D), INTENT(OUT)   :: U_F
  INTEGER,                          INTENT(INOUT) :: INFO

  CHARACTER*1 UPLO
  
  ! ----- 2. RUN FEASTINIT
  
  CALL feastinit(fpm)
  
  ! ----- 3. SOLVE THE STANDARD EIGENVALUE PROBLEM

  M0  = D  ! number of eignevalues requested
  
  ALLOCATE(E(M0)) ! array of eigenvalues
  ALLOCATE(RES(M0)) ! array of residuals
  ALLOCATE(X(D,M0)) ! matrix with eigenvectors
  E   = 0
  RES = 0
  X   = 0


  info_FEAST = 0
  Emin = E_L!-15.0 ! SEARCH INTERVAL: LOWER BOUND
  Emax = E_R! 15.0 ! SEARCH INTERVAL: UPPER BOUND
  UPLO = 'F'
 ! write(*,*) values
  !WRITE(*,*) '#MKL Sparse Eigenvalue, matrix dimension:',D
!  WRITE(*,*) D,SIZE(VALUES,1),SIZE(ROW_INDEX,1),SIZE(COLUMN,1),SIZE(FPM,1),Emin,Emax,M0,M1
!  WRITE(*,*) UPLO,D,SIZE(VALUES,1),SIZE(ROW_INDEX,1),SIZE(COLUMN,1),fpm,epsout,loop, &
!       &   Emin,Emax,M0,SIZE(E,1),SIZE(X,1),SIZE(X,2),M1,SIZE(res,1),info_FEAST
  CALL zfeast_hcsrev(UPLO,D,VALUES,ROW_INDEX,COLUMN,fpm,epsout,loop, &
       &   Emin,Emax,M0,E,X,M1,res,info_FEAST)
  IF(info.EQ.1) THEN
     PRINT  *,'FEAST OUTPUT INFO ',info_FEAST
     WRITE(*,*) 'GUESSED NUMBER OF EIGENVALUES:', m0
     WRITE(*,*) 'NUMBER OF EIGENVALUES FOUND:', m1
  END IF
  IF(info.eq.10) then 
     PRINT  *,'FEAST OUTPUT INFO ',info_FEAST
     WRITE(*,*) 'GUESSED NUMBER OF EIGENVALUES:', m0
     WRITE(*,*) 'NUMBER OF EIGENVALUES FOUND:', m1
     WRITE(*,*) 'EIGENVALUES:', E, D
     WRITE(*,*) 'EIGENVECTORS:', ABS(X)
!     CALL WRITE_MATRIX(D_MULTIFLOQUET,D_MULTIFLOQUET,ABS(X))
  END IF
  E_FLOQUET = E
  U_F       = X
  INFO      = info_FEAST

  DEALLOCATE(RES)
  DEALLOCATE(X)
  DEALLOCATE(E)
  
END SUBROUTINE MKLSPARSE_FULLEIGENVALUES

