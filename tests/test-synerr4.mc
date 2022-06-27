//OPIS: Cast u definiciji paremetra

unsigned funkcija(int (unsigned)param)
    return param;

int main() {
    int a;
    
    a = 3;
    a = funkcija(a);
    return 0;
}