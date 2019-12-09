#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include <Windows.h>

// Cabecera necesaria para las rutinas del runtime, es decir, todas
// aquellas que empiezan con cudaXXXXX.
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <curand.h>
#include <curand_kernel.h>

#include <CudaControler.h>
#include <Console.h>
#include <Values.h>

//Funciones para el timestamp
typedef LARGE_INTEGER timeStamp;
void getCurrentTimeStamp(timeStamp& _time);
timeStamp getCurrentTimeStamp();
double getTimeMili(const timeStamp& start, const timeStamp& end);
double getTimeSecs(const timeStamp& start, const timeStamp& end);


__global__ void setup_kernel ( curandState * state, unsigned long seed, unsigned int maxParticles)
{
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if(idx<maxParticles)
    curand_init ( seed, idx, 0, &state[idx] );
} 

// CUDA kernel. Each thread takes care of one element of c
__global__ void vecAdd(float *x, float *y, float *z,
							float *vx, float *vy, float *vz,
							float *lt, float *lr,
							curandState* state,
							float dt,
							unsigned int maxParticles,
							float vDecay)
{

	// Get our global thread ID
	int id = blockIdx.x*blockDim.x+threadIdx.x;
	if (id < maxParticles)
	{
		/* curand works like rand - except that it takes a state as a parameter */
		if(lr[id]<0.f)
		{
			//Space to create a particle
			int r = curand(&state[id]);

			x[id] = 0.f;
			y[id] = 0.f;
			z[id] = 0.f;

			vx[id] = 1.f;
			vy[id] = 1.f;
			vz[id] = 1.f;

			lt[id] = 0.f;
			lr[id] = 5.f;


		}else
		{
			//Velocity Decay
			vx[id] = vx[id] - vx[id]*vDecay*dt;
			vy[id] = vy[id] - vy[id]*vDecay*dt;
			vz[id] = vz[id] - vz[id]*vDecay*dt;

			//Position addition
			x[id] = vx[id]*dt;
			y[id] = vy[id]*dt;
			z[id] = vz[id]*dt;

			//Life set
			lr[id] = lr[id] - dt;
			lt[id] = lt[id] + dt;

		}
	}

}

void CudaControler::showDevices()
{
	/*
	    // Number of CUDA devices
		int devCount;
		cudaGetDeviceCount(&devCount);
		printf("CUDA Device Query...\n");
		printf("There are %d CUDA devices.\n", devCount);

		// Iterate through devices
		for (int i = 0; i < devCount; ++i)
		{
			// Get device properties
			printf("\nCUDA Device #%d\n", i);
			cudaDeviceProp devProp;
			cudaGetDeviceProperties(&devProp, i);
			printf("Major revision number:         %d\n",  devProp.major);
			printf("Minor revision number:         %d\n",  devProp.minor);
			printf("Name:                          %s\n",  devProp.name);
			printf("Total global memory:           %u\n",  devProp.totalGlobalMem);
			printf("Total shared memory per block: %u\n",  devProp.sharedMemPerBlock);
			printf("Total registers per block:     %d\n",  devProp.regsPerBlock);
			printf("Warp size:                     %d\n",  devProp.warpSize);
			printf("Maximum memory pitch:          %u\n",  devProp.memPitch);
			printf("Maximum threads per block:     %d\n",  devProp.maxThreadsPerBlock);
			for (int i = 0; i < 3; ++i)
			printf("Maximum dimension %d of block:  %d\n", i, devProp.maxThreadsDim[i]);
			for (int i = 0; i < 3; ++i)
			printf("Maximum dimension %d of grid:   %d\n", i, devProp.maxGridSize[i]);
			printf("Clock rate:                    %d\n",  devProp.clockRate);
			printf("Total constant memory:         %u\n",  devProp.totalConstMem);
			printf("Texture alignment:             %u\n",  devProp.textureAlignment);
			printf("Concurrent copy and execution: %s\n",  (devProp.deviceOverlap ? "Yes" : "No"));
			printf("Number of multiprocessors:     %d\n",  devProp.multiProcessorCount);
			printf("Kernel execution timeout:      %s\n",  (devProp.kernelExecTimeoutEnabled ? "Yes" : "No"));
		}
		*/
}

void CudaControler::setKernel()
{

	// Size, in bytes, of each vector
	size_t bytes = values::e_MaxParticles*sizeof(float);

	//Allocate memory for each vector in host
	h_x = (float*)malloc(bytes);	//position x
	h_y = (float*)malloc(bytes);	//position y
	h_z = (float*)malloc(bytes);  //position z
	
	//Allocate memory for each vector in device
	cudaMalloc(&d_x, bytes);
	cudaMalloc(&d_y, bytes);
	cudaMalloc(&d_z, bytes);

	cudaMalloc(&d_vx, bytes);
	cudaMalloc(&d_vy, bytes);
	cudaMalloc(&d_vz, bytes);

	cudaMalloc(&d_lt, bytes);
	cudaMalloc(&d_lr, bytes);

	// Initialize vectors on host
	/*
	memset(h_x, -1.f, h_x.size);
	memset(h_y, -1.f, h_y.size);
	memset(h_z, -1.f, h_z.size);
	*/

	// Copy host vectors to device
	cudaMemcpy( d_lr, h_z, bytes, cudaMemcpyHostToDevice);

	// Number of threads in each block
	blockSize = values::cu_BlockSize;

	// Number of blocks in grid
	gridSize = (int)ceil((float)values::e_MaxParticles/blockSize);
}

void CudaControler::closeKernel()
{
		// Release device memory
		cudaFree(d_x);
		cudaFree(d_y);
		cudaFree(d_z);
		cudaFree(d_vx);
		cudaFree(d_vy);
		cudaFree(d_vz);
		cudaFree(d_lt);
		cudaFree(d_lr);

		// Release host memory
		free(h_x);
		free(h_y);
		free(h_z);
}

void CudaControler::step(float dt)
{
	//Execute Kernel
	//Random device States
	curandState* devStates;
	cudaMalloc ( &devStates, values::e_MaxParticles*sizeof( curandState ) );
	setup_kernel<<<gridSize, blockSize>>> ( devStates, rand()%10000, values::e_MaxParticles);

	vecAdd<<<gridSize, blockSize>>>(d_x, d_y, d_z, 
										d_vx, d_vy, d_vz,
										d_lt, d_lr,
										devStates,
										dt,
										values::e_MaxParticles,
										values::p_VelocityDecay);
	
	cudaFree(devStates);

	// Copy array back to host
	size_t bytes = values::e_MaxParticles*sizeof(float);
	cudaMemcpy( h_x, d_x, bytes, cudaMemcpyDeviceToHost );
	cudaMemcpy( h_y, d_y, bytes, cudaMemcpyDeviceToHost );
	cudaMemcpy( h_z, d_z, bytes, cudaMemcpyDeviceToHost );

	for(int i = 0; i<values::e_MaxParticles; i++)
	{
		printf("P_%i---> x: %f, y: %f, z: %f \n", i, h_x[i], h_y[i], h_z[i]);
	}
}