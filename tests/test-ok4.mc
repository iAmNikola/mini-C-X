//OPIS: Sabiranje dva razlicita tipa varijabli unija pomocu kasta

union Pas {
    unsigned kuca;
    int ker;
};

union Macka {
    int maca;
    int macor;
};

int main() {
    union Pas pas;
    union Macka macka;
    int tmp;

    pas.ker = 6;
    pas.kuca = 1u;
    macka.maca = 9;
    tmp = (int)pas.kuca;
    return tmp + macka.maca;
}
