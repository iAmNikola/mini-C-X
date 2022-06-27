//OPIS: Sabiranje dva razlicita tipa varijabli unija

union Unija {
    int a;
    unsigned b;
};

int main() {
    union Unija x;
    union Unija y;

    y.b = 5u;
    x.a = 4;
    x.a = x.a + y.b;

    return 1;
}