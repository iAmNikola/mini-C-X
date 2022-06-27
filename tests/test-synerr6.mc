//OPIS: pozivanje atributa unije sa ',' umesto sa '.'

union Unija {
    int a;
    int b;
};

int main() {
    union Unija u;

    u,a = 5;

    return 0;
}