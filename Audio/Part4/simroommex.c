#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <limits.h>
#include <float.h>
#include "mex.h"
#include "matrix.h"

/*
 REFERENCE	Image method for efficiently simulating small-room acoustics
	J.B. Allen, D.A. Berkley
	JASA, 65 (4), Apr. 1979, pp. 943-950

OUTPUTS	H : impulse response of simulated room

INPUTS	Pmic	: microphone position (m)
			Psrc	: source position (m)
		
	Rdim	: room dimensions (m)
			Reflec	: reflection coefficients of the walls (0<=beta<=1)
			N	: number of points to be calculated (length of H)
			fs	: sampling frequency (Hz)

FORMATS	H[1:N]
			Pmic[x,y,z]
			Psrc[x,y,z]
			Rdim[Lx,Ly,Lz]
			Reflec[bx1,bx2,by1,by2,bz1,bz2]
			N
			fs
*/

/* constanten */
const	c=340;

void delimage(double Pmic[3], double Psrc[3],double Rdim[3], double nx, double ny, double nz, double *delays)
{

  /* variabelen */
  int	 i,j,k,l,m;
  double   rp[8*3];
  double   rt[3];
  double   tmp[3];
  double   nortmp;

  /* programma */
  i=1;
  for (l=-1;l<=1;l=l+2){
       for (j=-1;j<=1;j=j+2){
		for (k=-1;k<=1;k=k+2){
			rp[(i-1)*3]=Pmic[0]+l*Psrc[0];
			rp[(i-1)*3+1]=Pmic[1]+j*Psrc[1];
			rp[(i-1)*3+2]=Pmic[2]+k*Psrc[2];
			i=i+1;
		}
	}
  }
  rt[0]=2*Rdim[0]*nx;
  rt[1]=2*Rdim[1]*ny;
  rt[2]=2*Rdim[2]*nz;
  for (i=1;i<=8;i++){
	nortmp=0;
	for (m=1;m<=3;m++){
		tmp[m-1]=rt[m-1]-rp[(i-1)*3+m-1];
		nortmp=nortmp+(tmp[m-1])*(tmp[m-1]);
	}
	*(delays+i-1)=sqrt(nortmp);
  }
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{

  double *H;
  double Pmic[3],Psrc[3],Rdim[3],Reflec[6];
  double a[3],b[2],y[3];
  double *pp, *delays;
  double dist,fs;
  int    N;
  int    i,j,k,l;
  int    n1,n2,n3,nx,ny,nz,id;
  double gid,r1,tmp;

  /* geheugenallocatie */
  delays=(double *)mxCalloc(8,sizeof(double));

  /* converteer parameters */
  pp=mxGetPr(prhs[0]); 
  for (i=0;i<3;i++) Pmic[i]=*(pp+i);
  pp=mxGetPr(prhs[1]);    
  for (i=0;i<3;i++) Psrc[i]=*(pp+i);
  pp=mxGetPr(prhs[2]);    
  for (i=0;i<3;i++) Rdim[i]=*(pp+i);
  pp=mxGetPr(prhs[3]);    
  for (i=0;i<6;i++) Reflec[i]=*(pp+i);
  N = (int) *(mxGetPr(prhs[4]));
  fs = (double) *(mxGetPr(prhs[5]));

  /* geheugenallocatie */
  plhs[0]=mxCreateDoubleMatrix(N,1,mxREAL);
  H=mxGetPr(plhs[0]);

  /* program */
  dist=0;
  for (i=0;i<3;i++){
	Pmic[i]=Pmic[i]*fs/c;
	Psrc[i]=Psrc[i]*fs/c;
	Rdim[i]=Rdim[i]*fs/c;
	dist=dist+(Pmic[i]-Psrc[i])*(Pmic[i]-Psrc[i]);
  }
  dist=sqrt(dist);
  if (dist<0.5){
	*H=1;
	mexPrintf("Source and microphone are to close to each other");
	return;
  }
  n1=ceil(N/(2*Rdim[0]))+1;
  n2=ceil(N/(2*Rdim[1]))+1;
  n3=ceil(N/(2*Rdim[2]))+1;

  for (nx=-n1;nx<=n1;nx++){
	for (ny=-n2;ny<=n2;ny++){
		for (nz=-n3;nz<=n3;nz++){
		        delimage(Pmic,Psrc,Rdim,nx,ny,nz,delays);
			i=0;
			for (l=0;l<=1;l++){
				for (j=0;j<=1;j++){
					for (k=0;k<=1;k++){
						i=i+1;
						id=ceil(*(delays+i-1));
						if (id >= N) break;
						gid=pow(Reflec[0],(abs(nx-l)));
						gid=gid*pow(Reflec[1],(abs(nx)));
						gid=gid*pow(Reflec[2],(abs(ny-j)));
						gid=gid*pow(Reflec[3],(abs(ny)));
						gid=gid*pow(Reflec[4],(abs(nz-k)));
						gid=gid*pow(Reflec[5],(abs(nz)));
						gid=gid/id;
						*(H+id-1)=*(H+id-1)+gid;
					}
				}
			}
		}
	}
  }

  r1=exp(-0.06283185307180);
  b[0]=2*r1*cos(0.06283185307180);
  b[1]=-(r1*r1);
  a[0]=1;
  a[1]=-(1+r1);
  a[2]=r1;
  for (i=0;i<3;i++) {y[i]=0;}

  for (i=0;i<N;i++){
        tmp=*(H+i); 
	*(H+i)=0;
	for (j=0;j<3;j++) *(H+i)=*(H+i)+a[j]*y[j];
	y[2]=y[1];
	y[1]=y[0];
	y[0]=b[0]*y[1]+b[1]*y[2]+tmp;
 }

  mxFree(delays);

}



