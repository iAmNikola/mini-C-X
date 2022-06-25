union Unija {
    int add;
    unsigned b;
    int d;
};

union Pas {
    int kuca;
    int ker;
    int kujica;
};

union Unija funkcija(int parametar) {
    union Unija vracaj;
    vracaj.add = parametar;
    return vracaj;
}

int broj(union Pas param) {
    return param.kuca;
}

int main() {
    union Unija instanca;
    union Unija unija;
    union Pas pas;
    int result;

    instanca.add = 5;
    unija = funkcija(instanca.add);
    return broj(pas);
}