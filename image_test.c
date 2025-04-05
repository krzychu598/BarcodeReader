#include <stdio.h>
#include <stdlib.h>
#include "image.h"

//unsigned char * convert(ImageInfo* pImg, unsigned int height, unsigned char *result);
unsigned char* convert(unsigned char* result_buffer, unsigned int height,  ImageInfo* pImg);
unsigned char code[] = "1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ-._*";


void readcode(ImageInfo *pImg)
{
    unsigned int y = pImg->height / 2;
    unsigned char* result1 = malloc(20 * sizeof(unsigned char));
    unsigned char* result = convert(result1, y,  pImg);
    if(result){
    printf("Read result of barcode: %s", result);
    printf("\n");
    free(result);
    } else{
        printf("couldn't get result");
    }

}

int main(int argc, char *argv[])
{   
    if (sizeof(bmpHdr) != 54)
    {
        printf("Size of the bitmap header is invalid (%lu). Please, check compiler options.\n", sizeof(bmpHdr));
        return 1;
    }

    ImageInfo *pImg = readBmp("barcodes/ARKOcode39f.bmp");
    if (pImg == NULL)
    {
        printf("Error opening input file ARKOcode39f.bmp\n");
        return 1;
    }
    readcode(pImg);
    freeImage(pImg);

    ImageInfo *pImg2 = readBmp("barcodes/ARKOcode_moved.bmp");
    if (pImg2 == NULL)
    {
        printf("Error opening input file ARKOcode_moved.bmp\n");
        return 1;
    }
    readcode(pImg2);
    freeImage(pImg2);

    ImageInfo *pimg3 = readBmp("barcodes/x86.bmp");
    if (pimg3 == NULL)
    {
        printf("Error opening input file x86.bmp\n");
        return 1;
    }
    readcode(pimg3);
    freeImage(pimg3);

    return 0;
}