!***********************************************************************
! Computes the potential evapotranspiration using the Hargreaves and
! Samani formulation
! Hargreaves, G.H. and Z.A. Samani, 1985. Reference crop
! evapotranspiration from temperature. Transaction of ASAE 1(2):96-99.
!***********************************************************************
      MODULE PRMS_POTET_HS
        IMPLICIT NONE
        ! Local Variables
        CHARACTER(LEN=8), SAVE :: MODNAME
        ! Declared Parameters
        REAL, SAVE, ALLOCATABLE :: Hs_krs(:, :)
      END MODULE PRMS_POTET_HS

      INTEGER FUNCTION potet_hs()
      USE PRMS_POTET_HS
      USE PRMS_MODULE, ONLY: Process, Nhru
      USE PRMS_BASIN, ONLY: Active_hrus, Hru_route_order, Hru_area, Basin_area_inv, NEARZERO
      USE PRMS_CLIMATEVARS, ONLY: Basin_potet, Potet, Tavgc, Tminc, Tmaxc, Swrad
      USE PRMS_SET_TIME, ONLY: Nowmonth
      IMPLICIT NONE
! Functions
      INTRINSIC SQRT
      INTEGER, EXTERNAL :: declparam, getparam
      EXTERNAL read_error, print_module
! Local Variables
      INTEGER :: i, j
      REAL :: temp_diff, coef_kt, swrad_inch_day
      CHARACTER(LEN=80), SAVE :: Version_potet
!***********************************************************************
      potet_hs = 0

      IF ( Process(:3)=='run' ) THEN
        Basin_potet = 0.0D0
        DO j = 1, Active_hrus
          i = Hru_route_order(j)
          temp_diff = Tmaxc(i) - Tminc(i) ! should be mean monthlys???
!          swrad_mm_day = Swrad(i)/23.89/2.45
!          swrad_mm_day = Swrad(i)*0.04184/2.45
          swrad_inch_day = Swrad(i)*0.000673 ! Langleys->in/day
          coef_kt = 0.00185*(temp_diff**2) - 0.0433*temp_diff + 0.4023
          Potet(i) = Hs_krs(i, Nowmonth)*coef_kt*swrad_inch_day*SQRT(temp_diff)*(Tavgc(i)+17.8)
          IF ( Potet(i)<NEARZERO ) Potet(i) = 0.0
          Basin_potet = Basin_potet + Potet(i)*Hru_area(i)
        ENDDO
        Basin_potet = Basin_potet*Basin_area_inv

      ELSEIF ( Process(:4)=='decl' ) THEN
        Version_potet = '$Id: potet_hs.f90 6835 2014-10-10 19:18:29Z rsregan $'
        CALL print_module(Version_potet, 'Potential Evapotranspiration', 90)
        MODNAME = 'potet_hs'

        ALLOCATE ( Hs_krs(Nhru,12) )
        IF ( declparam(MODNAME, 'hs_krs', 'nhru,nmonths', 'real', &
     &       '0.0135', '0.005', '0.06', &
     &       'Potential ET adjustment factor - Hargreaves-Samani', &
     &       'Monthly (January to December) adjustment factor used in Hargreaves-Samani potential ET computations for each HRU', &
     &       'decimal fraction')/=0 ) CALL read_error(1, 'hs_krs')

!******Get parameters
      ELSEIF ( Process(:4)=='init' ) THEN
        IF ( getparam(MODNAME, 'hs_krs', Nhru*12, 'real', Hs_krs)/=0 ) CALL read_error(2, 'hs_krs')
      ENDIF

      END FUNCTION potet_hs
