union Unija {
    int add;
    unsigned b;
    int d;
};

union Pas {
    unsigned kuca;
    int ker;
};

union Unija funkcija(int parametar) {
    union Unija vracaj;
    vracaj.add = parametar;
    return vracaj;
}

unsigned broj(union Pas param) {
    return param.kuca;
}

int main() {
    union Unija instanca;
    union Unija unija;
    union Pas pas;
    int a;
    int b;

    a = 5;
    b = 10;
    instanca.b = (int)(a+b)+(unsigned)(5);
    unija = funkcija(instanca.add);
    return (int)(broj(pas));
}