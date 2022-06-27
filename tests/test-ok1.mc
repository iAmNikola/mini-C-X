//OPIS: Dve unije, sabiranje varijabli unija, prosledjivanje u funkciju, vracanje vrednosti varijable unije
//RETURN: 13

union Pas {
    unsigned kuca;
    int ker;
};

union Macka {
    int maca;
    int macor;
};

int vracaj(union Pas param) {
    return param.ker;
}

int main() {
    union Pas pas;
    union Macka macka;

    pas.kuca = 5u;
    pas.ker = 3;
    macka.maca = 10;
    pas.ker = pas.ker + macka.maca;
    return vracaj(pas);
}
