import java.util.Timer;


public class Test {

	static int s = 0;
	
	static final int rA = 1103515245;
	static final int rC = 12345;
	static final int rM = 0x7FFFFFFF;

	public static int rrand () {
		s = (rA * s + rC) & rM;
		return s;
	}
	
	public static int rand (int m) {
		int s = rrand();
		long x = s;
		x = x * m;
		x = x / 0x80000000L;
		
		return (int)x;
	}
	

	public static void dummy(int a, int b) {}
	
	public static long test(int N) {
		
		System.gc();

		long t = System.currentTimeMillis();
		IndexMinPQ<Integer> pq = new IndexMinPQ<Integer>(N);
		for (int i=0;i<N;++i) pq.insert(i,rand(N/2));
		for (int i=0;i<N;++i) pq.changeKey(i, rand(N/2));
		for (int i=0;i<N;++i) {
			pq.minKey();
			pq.delMin();
		}
		t = System.currentTimeMillis() - t;
		
		return t;
	}
	
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {

		// Pre-heat for JIT
		/*test(10000);
		test(10000);
		test(10000);
		test(10000);*/
		
		int N = Integer.parseInt(args[0]);
		int R = Integer.parseInt(args[1]);

		System.out.printf("N=%d\n%d iterations\n",N,R);
		
		int t=0;
		for (int i=0;i<R;++i) t+=test(N);

		t= t/R;
		System.out.printf("Time: %dms\n", t);
		
		
	}

}
