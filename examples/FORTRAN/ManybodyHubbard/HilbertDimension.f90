DOUBLE PRECISION FUNCTION  D_H(N_SITES,N_PARTICLES,stats) 

  !Calculates the number of states of N_particles bosos in N_sites lattice sites
  ! Wikipedia:
  ! D_B  = (N_particles + N_sites - 1)!)/(N_particles! * (L-1)!)))
  ! D_F  = N_sites!/(N_particles! (N_sites-N_particles)!)))
  IMPLICIT NONE
  INTEGER, INTENT(IN):: N_SITES,N_PARTICLES
  CHARACTER(LEN=*), INTENT(IN),OPTIONAL :: stats
  !DOUBLE PRECISION D_H

  INTEGER          :: N_,K_,i
  DOUBLE PRECISION :: Num,Den,N_STATES


  IF(PRESENT(stats)) THEN
     SELECT CASE (stats)
     CASE("B")

         IF(N_PARTICLES.GT.1) THEN
            N_ = N_SITES+N_PARTICLES-1;
            K_ = N_PARTICLES;
            
            Num = 1.0;
            do while (n_.gt.0) 
                Num = Num*n_;
                n_ = n_-1;
            end do
            Den = 1.0;
            do while (k_.gt.0)  !i = 1,k_-1
                Den = Den*k_;
                k_ = k_-1;
            end do
         ELSE
             num = n_sites
             den = 1
         END IF

     CASE("F")
        N_STATES = N_SITES!2*N_SITES
        N_ = N_STATES
        Num = 1.0;
        do while (n_.gt.0) 
           Num = Num*n_
           n_ = n_-1;
        end do
        k_ = N_STATES - N_PARTICLES
        Den = 1.0
        do while (k_.gt.0)
           Den = Den*k_;
           k_ = k_-1;
        end do
        k_ = N_PARTICLES
        do while (k_.gt.0) 
           Den = Den*k_;
           k_ = k_-1;
        end do

     CASE DEFAULT
        D_H = N_SITES
     END SELECT

     D_H = Num/Den;

  ELSE

     D_H = N_SITES

  END IF

END FUNCTION D_H


MODULE CREATIONDESTRUCTION

  implicit none
  private
  public :: A_DAGGER,A_,TUNNELING_

  interface A_DAGGER
    procedure A_DAGGER_INT,A_DAGGER_REAL
  end interface A_DAGGER

  interface A_
    procedure A_INT,A_REAL
  end interface A_

contains
    !Bosonic tunneling
    FUNCTION TUNNELING_(k,STATE) result(NEW_STATE)

    
        INTEGER, INTENT(IN) :: k
        INTEGER, DIMENSION(:), INTENT(IN) :: STATE
    
        DOUBLE PRECISION, DIMENSION(SIZE(STATE,1)) :: NEW_STATE
    
        !WRITE(*,*) k,NEW_STATE
        NEW_STATE      = STATE 
        IF(STATE(K).GT.0) THEN
            NEW_STATE(k)   = NEW_STATE(k) - 1            
            NEW_STATE(k+1) = NEW_STATE(k+1) + 1
            !NEW_STATE      = SQRT(1.0*STATE(K)*(STATE(k+1)+1))*NEW_STATE
        ELSE
            NEW_STATE = 0
        END IF  
       !WRITE(*,*) k,NEW_STATE
    END FUNCTION TUNNELING_


    !BOSONIC CREATION AND DESTRUCTION OPERATORE
    FUNCTION A_DAGGER_INT(k,STATE) result(NEW_STATE)

    
        INTEGER, INTENT(IN) :: k
        INTEGER, DIMENSION(:), INTENT(IN) :: STATE
    
        DOUBLE PRECISION, DIMENSION(SIZE(STATE,1)) :: NEW_STATE
    
        !WRITE(*,*) k,NEW_STATE
        NEW_STATE    = STATE 
        NEW_STATE(k) = NEW_STATE(k) + 1
        NEW_STATE    = SQRT(1.0*NEW_STATE(K))*NEW_STATE
               !WRITE(*,*) k,NEW_STATE
    END FUNCTION A_DAGGER_INT

    FUNCTION A_DAGGER_REAL(k,STATE) result(NEW_STATE)

    
        INTEGER, INTENT(IN) :: k
        DOUBLE PRECISION, DIMENSION(:), INTENT(IN) :: STATE
    
        DOUBLE PRECISION, DIMENSION(SIZE(STATE,1)) :: NEW_STATE
    
        NEW_STATE    = STATE 
        !WRITE(*,*) k,NEW_STATE
        NEW_STATE(k) = NEW_STATE(k) + 1
        NEW_STATE    = SQRT(1.0*NEW_STATE(K))*NEW_STATE
        !WRITE(*,*) k,NEW_STATE
    END FUNCTION A_DAGGER_REAL

    FUNCTION A_INT(k,STATE) result(NEW_STATE)
    !A_DAGGER |n> = sqrt(n+1) |n+1>
        IMPLICIT NONE
        INTEGER, INTENT(IN) :: K
        INTEGER, DIMENSION(:), INTENT(IN) :: STATE
    
        DOUBLE PRECISION, DIMENSION(SIZE(STATE,1)) :: NEW_STATE

        NEW_STATE    = STATE 
!        WRITE(*,*) k,NEW_STATE
        IF(STATE(k).GT.0) THEN
            NEW_STATE(k) = NEW_STATE(k) - 1
            NEW_STATE    = SQRT(1.0*NEW_STATE(K))*NEW_STATE
        ELSE
            NEW_STATE =0
        END IF
 !       WRITE(*,*) k,NEW_STATE
    END FUNCTION A_INT
    
    FUNCTION A_REAL(k,STATE) result(NEW_STATE)
    !A_DAGGER |n> = sqrt(n+1) |n+1>
        IMPLICIT NONE
        INTEGER, INTENT(IN) :: K
        DOUBLE PRECISION, DIMENSION(:), INTENT(IN) :: STATE
    
        DOUBLE PRECISION, DIMENSION(SIZE(STATE,1)) :: NEW_STATE

        NEW_STATE    = STATE 
        IF(STATE(k).GT.0) THEN
            NEW_STATE(k) = NEW_STATE(k) - 1
            NEW_STATE    = SQRT(1.0*NEW_STATE(K))*NEW_STATE
        ELSE
            NEW_STATE =0
        END IF
    END FUNCTION A_REAL


end module   CREATIONDESTRUCTION


SUBROUTINE Manybody_basis(D_BARE,N_SITES,N_BODIES,STATS,states_occ,INFO)

  IMPLICIT NONE
  INTEGER, INTENT(IN) :: D_BARE,N_SITES,N_BODIES
  CHARACTER(LEN=*),INTENT(IN):: stats
  INTEGER, DIMENSION(D_BARE,N_SITES), intent(out) :: states_occ
  INTEGER, INTENT(INOUT) :: INFO

  LOGICAL MORE
  INTEGER i,j,INTEGER_SPACE

  INTEGER, ALLOCATABLE,DIMENSION(:) :: STATE_

  i = 0
  STATES_OCC = 0
  MORE = .FALSE.

  INFO = 0
  SELECT CASE (stats)
  CASE("B")
     ALLOCATE(STATE_(N_SITES))
     STATE_ = 0
     STATE_(1) = N_BODIES  
     DO i=1,D_BARE        
        CALL COMP_NEXT(N_BODIES,N_SITES,STATE_,MORE)
        STATES_OCC(i,:) = STATE_
        !write(*,*) state_
     END DO
     
  CASE("F")

     IF(N_BODIES .LE. 2*N_SITES) THEN
        ALLOCATE(STATE_(N_SITES))
        STATE_=0
        j  =1
        INTEGER_SPACE = 2**N_SITES -1
        DO i=1,INTEGER_SPACE
            
            CALL BVEC_NEXT_GRLEX(N_SITES,STATE_)
            IF(SUM(STATE_) .EQ. N_BODIES) THEN
                STATES_OCC(j,:) = STATE_
                write(*,*) j
                j=j+1
            ELSE
                
            END IF  
        END DO  
     ELSE
        WRITE(*,*) "ERROR"
        WRITE(*,*) "THE NUMBER OF PARTICLES IS LARGER THAN THE NUMBER OF AVAILABLE STATES"
        INFO  = -1
     END IF

  END  SELECT

END SUBROUTINE Manybody_basis


SUBROUTINE TENSORMULT(N,A,B,C,INFO)
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: N
    COMPLEX*16, DIMENSION(N,N), INTENT(IN) :: A,B
    COMPLEX*16, DIMENSION(2*N,2*N), INTENT(OUT) :: C
    
    INTEGER i,j
    
    DO =1,N
        DO j=1,N
            C((i-1)*N+1:j*N,(i-1)*N+1:j*N) = A*B(i,j)
        END DO
    END DO
    
END SUBROUTINE TENSORMULT