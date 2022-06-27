//OPIS: Koriscenje 'neaktivne' varijable unije

union Unija {
    int a;
    int b;
};

int funkcija(int param) {
    return param + 5;
}

int main() {
    union Unija x;

    x.a = 4;

    return funkcija(x.b);
}