!***********************************************************************
!     WRITES NHM CSV SUMMARY FILE
!***********************************************************************
      MODULE PRMS_PRMS_SUMMARY
        IMPLICIT NONE
        ! Local Variables
        INTEGER, PARAMETER :: NVARS = 51
        CHARACTER(LEN=12), SAVE :: MODNAME
        INTEGER, SAVE :: Iunit
        INTEGER, SAVE, ALLOCATABLE :: Gageid_len(:)
        REAL, SAVE, ALLOCATABLE :: Segmentout(:), Gageout(:)
        CHARACTER(LEN=48), ALLOCATABLE :: Streamflow_pairs(:)
        CHARACTER(LEN=8), ALLOCATABLE :: Cfs_strings(:)
        CHARACTER(LEN=24) :: Fmt
        CHARACTER(LEN=40), SAVE :: Fmt2
        ! Declared Variables
        DOUBLE PRECISION, SAVE :: Basin_total_storage, Basin_surface_storage
        ! Declared Parameters
        INTEGER, SAVE, ALLOCATABLE :: Parent_poigages(:), Poi_gage_segment(:)
        CHARACTER(LEN=16), SAVE, ALLOCATABLE :: Poi_gage_id(:)
      END MODULE PRMS_PRMS_SUMMARY

      SUBROUTINE prms_summary()
      USE PRMS_PRMS_SUMMARY
      USE PRMS_MODULE, ONLY: Model, Process, Npoigages, Nsegment, Csv_output_file, Inputerror_flag, Nobs
      USE PRMS_CLIMATEVARS, ONLY: Basin_potet, Basin_tmax, Basin_tmin, Basin_potsw, Basin_ppt
      USE PRMS_FLOWVARS, ONLY: Basin_soil_moist, Basin_ssstor, Basin_soil_to_gw, &
     &    Basin_lakeevap, Basin_perv_et, Basin_actet, Basin_lake_stor, &
     &    Basin_gwflow_cfs, Basin_sroff_cfs, Basin_ssflow_cfs, Basin_cfs, Basin_stflow_in, &
     &    Basin_stflow_out, Seg_outflow
      USE PRMS_SET_TIME, ONLY : Nowyear, Nowmonth, Nowday
      USE PRMS_OBS, ONLY: Streamflow_cfs
      USE PRMS_INTCP, ONLY: Basin_intcp_evap, Basin_intcp_stor
      USE PRMS_SNOW, ONLY: Basin_pweqv, Basin_snowevap, Basin_snowmelt, Basin_snowcov, Basin_pk_precip
      USE PRMS_SRUNOFF, ONLY: Basin_imperv_stor, Basin_dprst_evap, Basin_imperv_evap, Basin_dprst_seep, &
     &    Basin_dprst_volop, Basin_dprst_volcl, Basin_hortonian
      USE PRMS_SOILZONE, ONLY: Basin_capwaterin, Basin_pref_flow_infil, Basin_prefflow, Basin_recharge, Basin_slowflow, &
     &    Basin_pref_stor, Basin_slstor, Basin_soil_rechr, Basin_sz2gw, Basin_dunnian
      USE PRMS_GWFLOW, ONLY: Basin_gwstor, Basin_gwin, Basin_gwsink, Basin_gwflow, &
     &    Basin_gwstor_minarea_wb, Basin_dnflow
      IMPLICIT NONE
! Functions
      INTRINSIC CHAR
      INTEGER, EXTERNAL :: declparam, declvar, getparam, getdim !, control_integer
      EXTERNAL :: read_error, PRMS_open_output_file, print_module, statvar_to_csv
      INTEGER, EXTERNAL :: getparamstring, control_string
! Local Variables
      INTEGER :: i, ios, ierr, foo !, statsON_OFF
      REAL :: gageflow
      CHARACTER(LEN=10) :: chardate
      CHARACTER(LEN=80), SAVE :: Version_prms_summary
!***********************************************************************
      IF ( Process(:3)=='run' ) THEN
        DO i = 1, Npoigages
          Segmentout(i) = Seg_outflow(Poi_gage_segment(i))
          Gageout(i) = Streamflow_cfs(Parent_poigages(i))
        ENDDO

        gageflow = 0.0
        IF ( Nobs>0 ) gageflow = Streamflow_cfs(1)
        Basin_total_storage = Basin_soil_moist + Basin_intcp_stor + Basin_gwstor + Basin_ssstor + Basin_pweqv + &
     &                        Basin_imperv_stor + Basin_lake_stor + Basin_dprst_volop + Basin_dprst_volcl
        Basin_surface_storage = Basin_intcp_stor + Basin_pweqv + Basin_imperv_stor + Basin_lake_stor + &
     &                          Basin_dprst_volop + Basin_dprst_volcl
        WRITE ( chardate, '(I4.4,2("-",I2.2))' ) Nowyear, Nowmonth, Nowday
        WRITE ( Iunit, Fmt2 ) chardate, &
     &          Basin_potet, Basin_actet, Basin_dprst_evap, Basin_imperv_evap, Basin_intcp_evap, Basin_lakeevap, &
     &          Basin_perv_et, Basin_snowevap, Basin_potsw, Basin_ppt, Basin_pk_precip, &
     &          Basin_tmax, Basin_tmin, Basin_snowcov, &
     &          Basin_total_storage, Basin_surface_storage, &
     &          Basin_dprst_volcl, Basin_dprst_volop, Basin_gwstor, Basin_imperv_stor, Basin_intcp_stor, Basin_lake_stor, &
     &          Basin_pweqv, Basin_soil_moist, Basin_ssstor, &
     &          Basin_pref_stor, Basin_slstor, Basin_soil_rechr, &
     &          Basin_capwaterin, Basin_dprst_seep, Basin_gwin, Basin_pref_flow_infil, Basin_recharge, Basin_snowmelt, &
     &          Basin_soil_to_gw, Basin_sz2gw, &
     &          Basin_gwsink, Basin_prefflow, Basin_slowflow, Basin_hortonian, Basin_dunnian, &
     &          Basin_stflow_in, Basin_stflow_out, Basin_gwflow, Basin_dnflow, &
     &          Basin_gwstor_minarea_wb, &
     &          Basin_cfs, Basin_gwflow_cfs, Basin_sroff_cfs, Basin_ssflow_cfs, gageflow, &
     &          (Segmentout(i), Gageout(i), i = 1, Npoigages)

! Declare procedure
      ELSEIF ( Process(:4)=='decl' ) THEN
        Version_prms_summary = '$Id: prms_summary.f90 7232 2015-03-09 22:49:39Z rsregan $'
        CALL print_module(Version_prms_summary, 'Output Summary              ', 90)
        MODNAME = 'prms_summary'

!       Open summary file
        IF ( control_string(Csv_output_file, 'csv_output_file')/=0 ) CALL read_error(5, 'csv_output_file')
        IF ( Model/=99 ) THEN
          CALL PRMS_open_output_file(Iunit, Csv_output_file, 'csv_output_file', 0, ios)
          IF ( ios/=0 ) STOP
        ENDIF

        Npoigages = getdim('npoigages')
        IF ( Npoigages==-1 ) CALL read_error(6, 'npoigages')
        IF ( Npoigages>0 ) THEN
          IF ( Npoigages/=Nobs .AND. Model/=99 ) THEN
            PRINT *, 'WARNING, possible Parameter File and Data File mismatch - nobs does not equal npoigages'
            PRINT *, '         nobs=', Nobs, ' npoigages=', Npoigages
            !IF ( Npoigages>Nobs ) STOP 'ERROR, npoigages>nobs'
          ENDIF
        ENDIF
        IF ( Model==99 .AND. Npoigages==0 ) Npoigages = 1

        IF ( declvar(MODNAME, 'basin_total_storage', 'one', 1, 'double', &
     &       'Basin area-weighted average storage in all water storage reservoirs', &
     &       'inches', Basin_total_storage)/=0 ) CALL read_error(3, 'basin_total_storage')
        IF ( declvar(MODNAME, 'basin_surface_storage', 'one', 1, 'double', &
     &       'Basin area-weighted average storage in all surface water storage reservoirs', &
     &       'inches', Basin_surface_storage)/=0 ) CALL read_error(3, 'basin_surface_storage')

        IF ( Npoigages>0 ) THEN
          ALLOCATE ( Parent_poigages(Npoigages) )
          IF ( declparam(MODNAME, 'parent_poigages', 'npoigages', 'integer', &
     &         '1', 'bounded', 'nobs', &
     &         'Index of streamflow measurement station in parent model', &
     &         'Index of measured streamflow station corresponding to each point of interest', &
     &         'none')/=0 ) CALL read_error(1, 'parent_poigages')
          ALLOCATE ( Poi_gage_segment(Npoigages) )
          IF ( declparam(MODNAME, 'poi_gage_segment', 'npoigages', 'integer', &
     &         '0', 'bounded', 'nsegment', &
     &         'Index of stream segment in child model', &
     &         'Index of stream segment corresponding to each point of interest', &
     &         'none')/=0 ) CALL read_error(1, 'poi_gage_segment')
          ALLOCATE ( Poi_gage_id(Npoigages) )
          IF ( declparam(MODNAME, 'poi_gage_id', 'npoigages', 'string', &
     &         '0', '0', '9999999', &
     &         'Identification number of streamflow measurement station', &
     &         'Identification number of streamflow measurement station corresponding to each point of interest', &
     &         'none')/=0 ) CALL read_error(1, 'poi_gage_id')
        ENDIF

! Initialize Procedure
      ELSEIF ( Process(:4)=='init' ) THEN
        IF ( Npoigages>0 ) THEN
          ALLOCATE ( Streamflow_pairs(Npoigages), Cfs_strings(Npoigages) )
          ALLOCATE ( Segmentout(Npoigages), Gageout(Npoigages), Gageid_len(Npoigages) )
        ELSE
          ALLOCATE ( Streamflow_pairs(1), Cfs_strings(1) )
          ALLOCATE ( Segmentout(1), Gageout(1), Gageid_len(1) )
          Streamflow_pairs = ' '
        ENDIF
        Cfs_strings = ',cfs,cfs'

        Basin_total_storage = 0.0D0
        Basin_surface_storage = 0.0D0

        IF ( Npoigages>0 ) THEN
          IF ( getparam(MODNAME, 'parent_poigages', Npoigages, 'integer', Parent_poigages)/=0 ) &
     &         CALL read_error(2, 'parent_poigages')
          IF ( getparam(MODNAME, 'poi_gage_segment', Npoigages, 'integer', Poi_gage_segment)/=0 ) &
     &         CALL read_error(2, 'poi_gage_segment')
          DO i = 1, Npoigages
            Poi_gage_id(i) = '                '
          ENDDO
          IF ( getparam(MODNAME, 'poi_gage_id', Npoigages, 'string', Poi_gage_id)/=0 ) &
     &         CALL read_error(2, 'poi_gage_id')
          !print *, poi_gage_id

          DO i = 1, Npoigages
            foo = getparamstring(MODNAME, 'poi_gage_id', Npoigages, 'string', &
     &            i-1, Poi_gage_id(i))
          ENDDO
          !print *, "second", poi_gage_id

          DO i = 1, Npoigages
            ierr = 0
            IF ( Parent_poigages(i)<1 .OR. Parent_poigages(i)>Nobs ) THEN
              ierr = 1
              PRINT *, 'ERROR, invalid parent_poigage for POI:', i, '; parent gage:', &
     &                 Parent_poigages(i), '; nobs:', Nobs
            ENDIF
            IF ( Poi_gage_segment(i)<1 .OR. Poi_gage_segment(i)>Nsegment ) THEN
              ierr = 1
              PRINT *, 'ERROR, invalid poi_gage_segment for POI:', i, '; child segment:', &
     &                 Poi_gage_segment(i), '; nsegment:', Nsegment
            ENDIF
            IF ( ierr==1 ) THEN
              Inputerror_flag = 1
              CYCLE
            ENDIF
            Gageid_len(i) = INDEX( Poi_gage_id(i), ' ' ) - 1
            IF ( Gageid_len(i)<0 ) Gageid_len(i) = INDEX( Poi_gage_id(i), CHAR(0) ) - 1
            !PRINT *, 'gageid_len ', Gageid_len(i), ' :', Poi_gage_id(i), ':'
            IF ( Gageid_len(i)<1 ) Gageid_len(i) = 0
            IF ( Gageid_len(i)>0 ) THEN
              IF ( Gageid_len(i)>23 ) Gageid_len(i) = 23
              WRITE (Streamflow_pairs(i), '(A,I4.4,2A)' ) ',seg_outflow_', Poi_gage_segment(i), ',runoff_', &
     &                                                    Poi_gage_id(i)(:Gageid_len(i))
            ELSE
              Gageid_len(i) = 4
              WRITE (Streamflow_pairs(i), '(2(A,I4.4))' ) ',seg_outflow_', Poi_gage_segment(i), ',runoff_', &
     &                                                    Parent_poigages(i)
            ENDIF
          ENDDO
          !print *, 'pairs', streamflow_pairs
        ENDIF

        WRITE ( Fmt, '(A,I4,A)' ) '( ', 2*Npoigages+14, 'A )'
        WRITE ( Iunit, Fmt ) 'Date,', &
     &          'basin_potet,basin_actet,basin_dprst_evap,basin_imperv_evap,basin_intcp_evap,basin_lakeevap,', &
     &          'basin_perv_et,basin_snowevap,basin_potsw,basin_ppt,basin_pk_precip,', &
     &          'basin_tmax,basin_tmin,basin_snowcov,', &
     &          'basin_total_storage,basin_surface_storage,', &
     &          'basin_dprst_volcl,basin_dprst_volop,basin_gwstor,basin_imperv_stor,basin_intcp_stor,basin_lake_stor,', &
     &          'basin_pweqv,basin_soil_moist,basin_ssstor,', &
     &          'basin_pref_stor,basin_slstor,basin_soil_rechr,', &
     &          'basin_capwaterin,basin_dprst_seep,basin_gwin,basin_pref_flow_in,basin_recharge,basin_snowmelt,', &
     &          'basin_soil_to_gw,basin_sz2gw,', &
     &          'basin_gwsink,basin_prefflow,basin_slowflow,basin_hortonian,basin_dunnian,', &
     &          'basin_stflow_in,basin_stflow_out,basin_gwflow,basin_dnflow,', &
     &          'basin_gwstor_minarea_wb,', &
     &          'basin_cfs,basin_gwflow_cfs,basin_sroff_cfs,basin_ssflow_cfs,streamflow_cfs1', &
     &          (Streamflow_pairs(i)(:Gageid_len(i)+25), i = 1, Npoigages)

        WRITE ( Iunit, Fmt ) 'year-month-day,', &
     &          'inches/day,inches/day,inches/day,inches/day,inches/day,inches/day,', &
     &          'inches/day,inches/day,Langleys,inches/day,inches/day,', &
     &          'degrees,degrees,fraction,', &
     &          'inches,inches,', &
     &          'inches,inches,inches,inches,inches,inches,', &
     &          'inches,inches,inches,', &
     &          'inches,inches,inches,', &
     &          'inches/day,inches/day,inches/day,inches/day,inches/day,inches/day,', &
     &          'inches/day,inches/day,', &
     &          'inches/day,inches/day,inches/day,inches/day,inches/day,', &
     &          'inches/day,inches/day,inches/day,inches/day,', &
     &          'fraction,', &
     &          'cfs,cfs,cfs,cfs,cfs', &
     &          (Cfs_strings(i), i = 1, Npoigages)

        WRITE ( Fmt2, '(A,I4,A)' )  '( A,', 2*Npoigages+NVARS, '(",",SPES10.3) )'
         !print *, 'Fmt: ', Fmt
         !print *, 'Fmt2: ', Fmt2

      ELSEIF ( Process(:5)=='clean' ) THEN
        !IF ( control_integer(statsON_OFF, 'statsON_OFF')/=0 ) statsON_OFF = 1
        !IF ( statsON_OFF==1 ) CALL statvar_to_csv()
        CLOSE ( Iunit )
      ENDIF

      END SUBROUTINE prms_summary

!***********************************************************************
!     statvar_to_csv - write a CSV file based on the statvar file
!***********************************************************************
      SUBROUTINE statvar_to_csv()
      IMPLICIT NONE
      INTEGER, EXTERNAL :: control_string, numchars
      EXTERNAL PRMS_open_input_file, PRMS_open_output_file
      ! Local Variable
      INTEGER :: inunit, numvariables, ios, i, outunit, ts, yr, mo, day, hr, mn, sec, num
      INTEGER, ALLOCATABLE :: varindex(:), nc(:)
      REAL, ALLOCATABLE :: values(:)
      CHARACTER(LEN=32), ALLOCATABLE :: varname(:)
      CHARACTER(LEN=128), SAVE :: statvar_file, statvar_file_csv
      CHARACTER(LEN=10) :: chardate
      CHARACTER(LEN=13) :: fmt
      CHARACTER(LEN=17) :: fmt3
      CHARACTER(LEN=27) :: fmt2
!***********************************************************************
      IF ( control_string(statvar_file, 'stat_var_file')/=0 ) CALL read_error(5, 'statvar.out')
      CALL PRMS_open_input_file(inunit, statvar_file, 'stat_var_file', 0, ios)
      IF ( ios/=0 ) STOP 'ERROR, opening statvar file'
      statvar_file_csv = statvar_file(:numchars(statvar_file))//'.csv'
      CALL PRMS_open_output_file(outunit, statvar_file_csv, 'statvar_csv', 0, ios)
      IF ( ios/=0 ) STOP 'ERROR, opening statvar CSV file'
      READ ( inunit, * ) numvariables
      ALLOCATE ( varname(numvariables), varindex(numvariables), values(numvariables), nc(numvariables) )
      DO i = 1, numvariables
        READ ( inunit, '(A,I3)', IOSTAT=ios ) varname(i)
        IF ( ios/=0 ) STOP 'ERROR, reading statvar file'
        num = numchars(varname(i))
        READ ( varname(i)(num+1:32), '(I5)' ) varindex(i)
        WRITE ( varname(i), '(A,I5.5)' ) varname(i)(:num)//'_', varindex(i)
        nc(i) = num + 6
      ENDDO
      WRITE ( fmt, '(A,I5,A)' ) '( A, ', 2*numvariables, 'A )'
      WRITE ( outunit, fmt ) 'Date,', ( varname(i)(:nc(i)), ',', i = 1, numvariables )
      WRITE ( fmt3, '(A,I5,A)' ) '(A, ', 2*numvariables, '(I5,A))'
      WRITE ( outunit, fmt3 ) 'date,', ( varindex(i), ',', i = 1, numvariables )
      WRITE ( fmt2, '(A,I6,A)' ) '( A, ', numvariables, '(",",E14.6) )'
      DO WHILE ( ios/=-1 )
        READ ( inunit, *, IOSTAT=ios ) ts, yr, mo, day, hr, mn, sec, (values(i), i = 1, numvariables )
        IF ( ios==-1 ) EXIT
        IF ( ios/=0 ) THEN
          PRINT *, 'ERROR, reading statvar file values, IOSTAT:', ios
          PRINT *, ts, yr, mo, day, hr, 'number of variables:', numvariables
          PRINT *, (values(i), i = 1, numvariables )
          STOP 
        ENDIF
        WRITE ( chardate, '(I4.4,2("-",I2.2))' )  yr, mo, day
        WRITE ( outunit, fmt2 ) chardate, (values(i), i = 1, numvariables )
      ENDDO
      CLOSE ( outunit )
      END SUBROUTINE statvar_to_csv
