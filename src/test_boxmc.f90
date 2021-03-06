!-------------------------------------------------------------------------
! This file is part of the tenstream solver.
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
! 
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
! 
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! Copyright (C) 2010-2015  Fabian Jakub, <fabian@jakub.com>
!-------------------------------------------------------------------------

program main
      use m_boxmc, only : t_boxmc,t_boxmc_8_10,t_boxmc_1_2,t_boxmc_3_10
      use m_optprop, only : t_optprop_1_2,t_optprop_8_10
      use mpi
      use m_data_parameters, only : mpiint,ireals,iintegers,one,zero, init_mpi_data_parameters,i1
      use m_eddington, only : eddington_coeff_zdun
      use m_helper_functions, only: deg2rad,delta_scale

      implicit none

      real(ireals) :: bg(3),delta_bg(3),delta1_bg(3),S(10),T(8),T3(3),phi0,theta0,dx,dy,dz
      real(ireals) :: S_tol(10),T_tol(8),T3_tol(3),S2(2),T1(1),S2_tol(2),T1_tol(1)

      integer(iintegers),parameter :: Niter=10
      real(ireals) :: Siter(Niter,size(S) ), Titer(Niter,size(T) )
      real(ireals),allocatable,dimension(:) :: dir2dir_coeff,dir2diff_coeff,diff2diff_coeff

      integer(iintegers) :: src=1,iter
      integer(mpiint) :: myid,ierr,numnodes

      real(ireals) :: tau,w,g,c1,c2,c3,p0,p1,planck(2)
      real(ireals) :: a11,a12,a13,a23,a33,g1,g2,b1,b2

      type(t_boxmc_8_10) :: bmc_8_10
      type(t_boxmc_3_10) :: bmc_3_10
      type(t_boxmc_1_2) :: bmc_1_2

      type(t_optprop_8_10) OPP_8_10
      type(t_optprop_1_2) OPP_1_2


      phi0 = 0.
      theta0=45.


      dx=100
      dy=dx
      dz=50
      bg = [1e-3, 1e-6, .0 ]

      dx=200
      dy=dx
      dz=100
      bg = [1e-3/2, 1e-6/2, .0 ]


      print *,'Testing boxmc...',bg
      call MPI_Init(ierr)
      call MPI_Comm_Rank(MPI_COMM_WORLD, myid,ierr)
      call mpi_comm_size(MPI_COMM_WORLD, numnodes,ierr)

      call init_mpi_data_parameters(MPI_COMM_WORLD)

      call bmc_8_10%init(MPI_COMM_WORLD)
      call bmc_3_10%init(MPI_COMM_WORLD)
      call bmc_1_2%init(MPI_COMM_WORLD)

      do src=1,3
          call bmc_3_10%get_coeff(MPI_COMM_WORLD,bg,src,.True.,phi0,theta0,dx,dy,dz,S,T3,S_tol,T3_tol)
          if(myid.eq.0) write(*, FMT='( " direct transmission chan",I3,":: ",3(es10.3)," :: diffuse ",10(es10.3)  )' ) src,T3,S
      enddo
      do src=1,10
          call bmc_8_10%get_coeff(MPI_COMM_WORLD,bg,src,.False.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
          if(myid.eq.0) write(*, FMT='( " diffuse transmission chan",I3,":: ",10(es10.3)," :: emission ",es10.3  )' ) src,S,one-sum(S)
      enddo

      if(.False.) then
        bg = [1e-3, 1e-3, .0 ]
        call bmc_1_2%get_coeff(MPI_COMM_WORLD,bg,-1,.False.,phi0,theta0,dx,dy,dz,S2,T1,S2_tol,T1_tol)
        if(myid.eq.0) write(*, FMT='( " diffuse emission :: ",2(es10.3),"  :: ",2(es10.3) )' ) S2(1:2),one-S2(1:2)

        call bmc_8_10%get_coeff(MPI_COMM_WORLD,bg,-1,.False.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
        if(myid.eq.0) write(*, FMT='( " diffuse emission(-1)::  :: ",10(es10.3)," :: ",10(es10.3)  )' ) S,one-S
        print *,''
        print *,'sum S:',sum(S)
        if(myid.eq.0) write(*, FMT='( " hohlraum ::  :: ",10(es10.3)," :: ",10(es10.3)  )' ) 2*(dx*dy+dy*dz+dz*dx) * (one-S)
        print *,''

        do src=1,3
          call bmc_3_10%get_coeff(MPI_COMM_WORLD,bg,src,.True.,phi0,theta0,dx,dy,dz,S,T3,S_tol,T3_tol)
          if(myid.eq.0) write(*, FMT='( " direct transmission chan",I3,":: ",3(es10.3)," :: diffuse ",10(es10.3)  )' ) src,T3,S
        enddo

        print *,''
        print *,''

        do src=1,10
          call bmc_8_10%get_coeff(MPI_COMM_WORLD,bg,src,.False.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
          if(myid.eq.0) write(*, FMT='( " diffuse transmission chan",I3,":: ",10(es10.3)," :: emission ",es10.3  )' ) src,S,one-sum(S)
        enddo

        print *,''
        print *,''
        do src=1,8
          call bmc_8_10%get_coeff(MPI_COMM_WORLD,bg,src,.True.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
          if(myid.eq.0) write(*, FMT='( " direct transmission chan",I3,":: ",8(es10.3)," :: diffuse ",10(es10.3)  )' ) src,T,S
        enddo

        print *,''

        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu( 0):  ",   es10.3   )' ) one-exp(-bg(1)*dz )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(05):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(05._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(15):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(15._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(25):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(25._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(35):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(35._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(45):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(45._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(55):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(55._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(65):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(65._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(75):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(75._ireals) ) )
        if(myid.eq.0) write(*, FMT='( " diffuse 1-exp(tau)/mu(85):  ",   es10.3   )' ) one-exp(-bg(1)*dz / cos(deg2rad(85._ireals) ) )

        print *,''

        tau = (bg(1)+bg(2))*dz
        w   = bg(2)/(bg(1)+bg(2))
        g   = bg(3)
        planck = one

        call eddington_coeff_zdun ( tau , w, g, cos(deg2rad(theta0)), a11, a12, a13, a23, a33, g1, g2 )
        if(tau.gt.0.01_ireals) then
          p0 = planck(1)
          p1 = (planck(1)-planck(2))/tau
        else
          p0 = .5_ireals*sum(planck)
          p1 = zero
        endif
        c1 = g1*(p0+p1*tau)
        c2 = g2*p1
        c3 = g1*p0
        b1 = ( -a11*(c1+c2) - a12*(c3-c2) + c2+c3 )  
        b2 = ( -a12*(c1+c2) - a11*(c3-c2) + c1-c2 )  
        if(myid.eq.0) write(*, FMT='( "eddington coeffs   ", 1(es10.3),"   ::   ",2(es10.3)," :: ",4(es10.3) )' ) a33,a13,a23,g1,g2,b1,b2

      endif

      if(.False.) then

        call OPP_8_10%init(dx,dy,[phi0],[theta0],MPI_COMM_WORLD)

        allocate( dir2dir_coeff(OPP_8_10%OPP_LUT%dir_streams**2) )
        allocate( dir2diff_coeff(OPP_8_10%OPP_LUT%dir_streams*OPP_8_10%OPP_LUT%diff_streams) )
        allocate( diff2diff_coeff(OPP_8_10%OPP_LUT%diff_streams**2) )

        src=i1 ! attention: output below is always only for src==1
        bg = [1e-4, 1e-6, .8 ]
        delta_bg = bg
        delta1_bg = bg
        call delta_scale(delta1_bg(1),delta1_bg(2),delta1_bg(3),delta1_bg(3)**1.5_ireals )
        call delta_scale(delta_bg(1),delta_bg(2),delta_bg(3) )
        if(myid.eq.0) then
          print *,'unscaled optprop',bg
          print *,'  scaled optprop',delta_bg
          print *,'1.5 aled optprop',delta1_bg
        endif

        call bmc_8_10%get_coeff(MPI_COMM_WORLD,bg,src,.True.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
        if(myid.eq.0) write(*, FMT='( " direct normal     ", 8(es10.3), "  ::  ",10(es10.3)  )' ) T,S


        call bmc_8_10%get_coeff(MPI_COMM_WORLD,delta_bg,src,.True.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
        if(myid.eq.0) write(*, FMT='( " direct deltascaled", 8(es10.3), "  ::  ",10(es10.3)  )' ) T,S

        call bmc_8_10%get_coeff(MPI_COMM_WORLD,delta1_bg,src,.True.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
        if(myid.eq.0) write(*, FMT='( " direct 1.5  scaled", 8(es10.3), "  ::  ",10(es10.3)  )' ) T,S

        call OPP_8_10%get_coeff(dz,delta_bg(1),delta_bg(2),delta_bg(3),.True. ,dir2dir_coeff ,[phi0,theta0])
        call OPP_8_10%get_coeff(dz,delta_bg(1),delta_bg(2),delta_bg(3),.False.,dir2diff_coeff,[phi0,theta0])
        if(myid.eq.0) write(*, FMT='( " direct LUT        ", 8(es10.3), "  ::  ",10(es10.3)  )' ) dir2dir_coeff(1:OPP_8_10%OPP_LUT%dir_streams),dir2diff_coeff(1:OPP_8_10%OPP_LUT%diff_streams)

        tau = (delta_bg(1)+delta_bg(2))*dz
        w   = delta_bg(2)/(delta_bg(1)+delta_bg(2))
        g   = delta_bg(3)
        call eddington_coeff_zdun ( tau , w, g, cos(deg2rad(theta0)), a11, a12, a13, a23, a33, g1, g2 )

        if(myid.eq.0) write(*, FMT='( "directeddington    ", 1(es10.3),"                                                                       ::   ",2(es10.3)," :: ",2(es10.3) )' ) a33,a13,a23,g1,g2
      endif

      if(.False.) then
        src=6
        do iter=1,Niter
          tau = 1e-6
!          w = dble(iter)/10._ireals-1e-3_ireals
          w = .9
          g = .0_ireals
          bg = [tau*(one-w)/dz, tau*w/dz, g ]
          bg = [1e-6,1e-6,0.]
          call bmc_8_10%get_coeff(MPI_COMM_WORLD,bg,src,.True.,phi0,theta0,dx,dy,dz,S,T,S_tol,T_tol)
          if(myid.le.1) write(*, FMT='( "iter ",I2," direct ", 8(f10.5), "::",10(f10.5)  )' ) iter,T,S

          Siter(iter,:) = S
          Titer(iter,:) = T
        enddo

      if(myid.eq.0) then
        print *,''
        print *,''

        write(*, FMT='( "    mean    :  ",8(f10.5) ,"::",10(f10.5) )' ) sum(Titer,dim=1 )/Niter  , sum(Siter,dim=1 )/Niter
        write(*, FMT='( "    stddev  :  ",8(f10.5) ,"::",10(f10.5) )' ) sqrt(one*Niter*numnodes)* (sqrt(sum(Titer**2,dim=1 )/Niter - (sum(Titer,dim=1 )/Niter)**2) ),  &
                                                                        sqrt(one*Niter*numnodes)* (sqrt(sum(Siter**2,dim=1 )/Niter - (sum(Siter,dim=1 )/Niter)**2) )
        write(*, FMT='( "rel stddev  :  ",8(f10.5) ,"::",10(f10.5) )' ) sqrt(one*Niter*numnodes)* (sqrt(sum(Titer**2,dim=1 )/Niter - (sum(Titer,dim=1 )/Niter)**2) / (sum(Titer,dim=1 )/Niter)), &
                                                                        sqrt(one*Niter*numnodes)* (sqrt(sum(Siter**2,dim=1 )/Niter - (sum(Siter,dim=1 )/Niter)**2) / (sum(Siter,dim=1 )/Niter))
        print *,''

      endif
      call mpi_barrier(mpi_comm_world,ierr)
      if(myid.eq.1) then
        print *,''
        print *,''

        write(*, FMT='( "    mean    :  ",8(f10.5) ,"::",10(f10.5) )' ) sum(Titer,dim=1 )/Niter  , sum(Siter,dim=1 )/Niter
        write(*, FMT='( "    stddev  :  ",8(f10.5) ,"::",10(f10.5) )' ) sqrt(one*Niter)*(sqrt(sum(Titer**2,dim=1 )/Niter - (sum(Titer,dim=1 )/Niter)**2) )  , &
                                                                        sqrt(one*Niter)*(sqrt(sum(Siter**2,dim=1 )/Niter - (sum(Siter,dim=1 )/Niter)**2) )
        write(*, FMT='( "rel stddev  :  ",8(f10.5) ,"::",10(f10.5) )' ) sqrt(one*Niter)*(sqrt(sum(Titer**2,dim=1 )/Niter - (sum(Titer,dim=1 )/Niter)**2) / (sum(Titer,dim=1 )/Niter)), &
                                                                        sqrt(one*Niter)*(sqrt(sum(Siter**2,dim=1 )/Niter - (sum(Siter,dim=1 )/Niter)**2) / (sum(Siter,dim=1 )/Niter))
        print *,''

      endif

      endif

      !        od_sca = tau*w
!        op_bg = [tau*(one-w)/dz, od_sca*(one-g)/dz, zero ]
!        call bmc_get_coeff_8_10(MPI_COMM_WORLD,op_bg,src,.True.,delta_scale,phi0,theta0,dx,dy,dz,S_out,Sdir_out,S_tol,T_tol)
!        if(myid.eq.0) write(*, FMT='( i2," direct ", 8(f10.5), "::",10(f10.5)  )' ) iter,Sdir_out,S_out
!      enddo
!      if(myid.eq.0) write(*, FMT='( i2," direct ", 8(f10.5), "::",10(f10.5)  )' ) iter,Sdir_out,S_out
!
!      if(.False.) then
!        print *,'Testing optprop'
!        call optprop_8_10_init(dx,dy,[phi0],[theta0],MPI_COMM_WORLD)
!
!        optprop_8_10_debug = .True.
!        
!        tau = 1e-0_ireals/dz
!        w = .9_ireals
!        g = .9_ireals
!        allocate(coeff(dir_streams*diff_streams) )
!        call optprop_8_10_lookup_coeff(dz,tau ,w,g,direct,coeff,[zero,zero])
!
!      endif
        call mpi_barrier(MPI_COMM_WORLD,ierr)
        call MPI_Finalize(ierr)

end program
